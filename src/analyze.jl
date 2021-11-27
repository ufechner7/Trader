using CSV, DataFrames, PyPlot, Dates, TimeZones, Impute, Statistics, GLM, Parameters

# global variables
INDEX = 1
TDB   = nothing
T0            = 0
RATING_TAB    = nothing
STOP          = false      

const NoDataFrame = Union{Nothing, DataFrame}

@enum Mode INIT=1 RATING=2 MIXED=3 STOPPED=4

@with_kw mutable struct State @deftype Int64
   t0                =  0                  # start time [s]
   index             =  1                  # last index of the input data frame
   mode::Mode        = INIT
   df                = nothing             # input data frame
   tdb::NoDataFrame  = nothing             # trading data frame
   rdb::NoDataFrame  = nothing             # rating data frame
   rel_price_table::NoDataFrame = nothing  # prices relative to buying time
   markets::Vector{String}      = []       # currently owned coins
end

include("performance.jl")

function buy(df, tdb, rp_table, time, market, amount; force=false, reason="")
    global FEE, T0
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_EUR) - sum(subset.SELL_EUR)
    cash = calc_cash(df, tdb)
    if (old_amount < 0.01 || force && old_amount <= MAX_TRADE + 0.01) && cash >= amount
        rate = last(df[!, market])
        coins = amount / rate * FEE
        total = calc_total(df, tdb) + coins * rate - amount
        v = [time, (time-T0)/3600, market, 0.0, amount, 0.0, coins, 0.0, 0.0, cash-amount, total, 0.0, reason]
        rel_price_table(df, time, rp_table; ref_market=market)
        push!(tdb, v)
        return true
    end
    return false
end

# sell all coins of a given market
function sell(df, tdb, time, market; reason="")
    global T0
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_COINS) - sum(subset.SELL_COINS)
    cash = calc_cash(df, tdb)
    if old_amount > 0.01
        rate = last(df[!, market])
        # println("Sell: ", market, " rate: ", rate)
        sell_eur = old_amount * rate
        total = calc_total(df, tdb)
        v = [time, (time-T0)/3600, market, sell_eur, 0.0, old_amount, 0.0, 0.0, 0.0, cash+sell_eur, total, 0.0, reason]
        push!(tdb, v)
    end
end

function sell_all(df, tdb, markets)
    global STOP = true
    time = last(df.TIME)
    for market in markets
        sell(df, tdb, time, market)
    end
end

function check(df, tdb, rp_table; prn=true)
    global INDEX, MAX_TRADE, MIN_DROP, MIN_DROP_24
    global RATING_TAB, STOP
    local top_ratings
    # create view to db with the first INDEX rows
    view = df[1:INDEX, :]
    by_hour, by_day = overview(view)
    top_ratings=nothing

    # update rp_table
    time = df.TIME[INDEX]
    rel_price_table(df, time, rp_table)

    # every hour
    if mod(INDEX, 60) == 0 
        # println("==> hour")
        time = df.TIME[INDEX]
        RATING_TAB=rating_table(view, 10000; filter=false)
        update_total(view, tdb, time)
        if INDEX > DAYS*24*60
            perf = find_performance(view, tdb, time, RATING_TAB)
            if ! isnothing(perf)
                for row in eachrow(perf)
                    market = row.MARKET
                    time = df.TIME[INDEX]
                    if row.RATING < MAX_RATING 
                        if prn println("==> Sell: ", market) end
                        sell(view, tdb, time, market; reason="row.RATING < MAX_RATING")
                    end
                end
            end
        end
    end

    # every minute: buy and sell if required
    for row in eachrow(by_hour)
        market = row.MARKET
        time = df.TIME[INDEX]
        if ! STOP && row.RISE_1h >= MAX_RISE 
            if INDEX < DAYS*24*60 
                buy(view, tdb, rp_table, time, market, MAX_TRADE; reason="RISE_1h >= MAX_RISE")
            else
                rating = market_rating(RATING_TAB, market)
                if rating > MIN_RATING # || row.RISE_1h >= MAX_RISE 
                    cash=calc_cash(view,tdb)
                    if cash >= KEEP
                        buy(view, tdb, rp_table, time, market, MAX_TRADE; reason="rating > MIN_RATING")
                        cash=calc_cash(view,tdb)
                        if cash >= KEEP
                            if cash >= 0.5*MAX_TRADE && cash < MAX_TRADE
                                buy(view, tdb, rp_table, time, market, cash; reason="rating > MIN_RATING")
                            else
                                buy(view, tdb, rp_table, time, market, MAX_TRADE; reason="rating > MIN_RATING")
                            end
                        end
                    end
                end
            end            
        end
        if row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24
            sell(df, tdb, time, market; reason="row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24")
        end
    end

    # every INTERVAL hours: evaluate performance, sell and buy
    if mod(INDEX, 60*INTERVAL) == 0 
        time = df.TIME[INDEX]
        perf = find_performance(view, tdb, time, RATING_TAB)
        top_ratings = rating_table(view, 8, filter=false)
        # println(top_ratings.RATING)
        
        if ! isnothing(perf)
            sort!(perf, [:PERF], rev=true)
            if prn println(perf) end
            market = last(perf.MARKET)
            
            # best_markets = (first(sort(rp_table, [:REL_PRIZE], rev=true),6)).MARKET
            # if ! (market in best_markets)
            if last(perf.PERF) < 1.0 
                if prn println("Selling: ", market) end
                sell(view, tdb, time, market; reason="last(perf.PERF) < 1.0 "*string(round(last(perf.PERF),digits=3)))
                
                if INDEX < DAYS*24*60 # rating calculation is only reliable after DAYS days
                    # markets = (perf.MARKET)
                    markets = (first(sort(rp_table, [:REL_PRIZE], rev=true),6)).MARKET
                else
                    markets = (top_ratings.MARKET)
                    if prn println(top_ratings) end
                end
                cash = calc_cash(view, tdb)
                amount_to_use = cash
                if cash >= MAX_TRADE
                    amount_to_use = MAX_TRADE
                end
                # println("==> ", markets)
                i = 1
                for market in markets   
                    flag = false
                    if INDEX >= DAYS*24*60
                        rating = market_rating(RATING_TAB, market)
                        flag = rating > MIN_RATING 
                    else 
                        performance = rel_price(rp_table, market)
                        if performance > 1.01
                            flag = true
                        end
                        flag = true          
                    end
                    if ! STOP && flag && buy(view, tdb, rp_table, time, market, amount_to_use; force=true, reason="every 12h: time < 4d or rating_ >= rating(RATING_TAB, market)")
                        if prn println("Buying: ", market, " time: ", (time-T0)/3600) end
                        cash = calc_cash(view, tdb)
                        if cash < 0.5 * MAX_TRADE break end
                        amount_to_use = cash
                        if cash >= MAX_TRADE
                            amount_to_use = MAX_TRADE
                        end                       
                    end
                    i += 1
                end
            end
        end

    end
    INDEX+=1
    top_ratings
end

function trade(df; n=0, prn=true)
    global RATING_TAB
    global STOP = false
    RATING_TAB = nothing
    top_ratings = nothing
    if n == 0
        n = size(df)[1]
    end
    tdb = trade_db(df, START_KAPITAL)

    time = df.TIME[INDEX]
    rp_table = rel_price_table(df, time)
    view = df[1:INDEX, :]
    for market in PREFER
        buy(view, tdb, rp_table, time, market, MAX_TRADE; reason="market in PREFER")
    end
    vec=Float64[]
    j = 0
    for i in WAIT:n
        time = df.TIME[INDEX]
        check(df, tdb, rp_table; prn=prn)
        if ! STOP && i > 60*24*4 && last(tdb.TOTAL)/maximum(tdb.TOTAL[end-12:end]) < STOP_LIMIT
            STOP=true
            println("STOP at ", (time-T0)/3600)
            #     update_total(view, tdb, time)
            markets = list_markets(tdb)
            view = df[1:INDEX, :]
            println(overview(view))
            println(markets)
            sell_all(view, tdb, markets)
            #     break
        end
        if STOP
            if j > 60*24*1.5
                STOP=false
                 println("START at ", (time-T0)/3600)
            end
            j += 1
        end
    end
    tdb
end

function main()
    if true
        by_hour, by_day = overview(df)
        println(by_hour)
        println(by_day)
    else
        tdb=test3(df)
        plot_total(tdb)
    end
end

include("constants.jl")
include("basic.jl")
include("rel_prices.jl")
include("trade_db.jl")

include("utils.jl")
include("tests.jl")
include("plotting.jl")
include("logging.jl")

df = read_log(logfiles())
main()

# p1 = plot(df.BTC_EUR, label="BTC_EUR")
