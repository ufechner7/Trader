using CSV, DataFrames, PyPlot, Dates, TimeZones, Impute, Statistics, GLM, Parameters

function buy(st, view, rp_table, market, amount; force=false, reason="")
    global FEE
    subset = filter(row -> row.MARKET == market, st.tdb)
    old_amount = sum(subset.BUY_EUR) - sum(subset.SELL_EUR)
    cash = calc_cash(view, st.tdb)
    if (old_amount < 0.01 || force && old_amount <= MAX_TRADE + 0.01) && cash >= amount
        rate = last(view[!, market])
        coins = amount / rate * FEE
        total = calc_total(view, st.tdb) + coins * rate - amount
        v = [st.time, st.rel_time/3600, market, 0.0, amount, 0.0, coins, 0.0, 0.0, cash-amount, total, 0.0, reason]
        rel_price_table(view, time, rp_table; ref_market=market)
        push!(st.tdb, v)
        return true
    end
    return false
end

# sell all coins of a given market
function sell(st, view, market; reason="")
    subset = filter(row -> row.MARKET == market, st.tdb)
    old_amount = sum(subset.BUY_COINS) - sum(subset.SELL_COINS)
    cash = calc_cash(view, st.tdb)
    if old_amount > 0.01
        rate = last(view[!, market])
        # println("Sell: ", market, " rate: ", rate)
        sell_eur = old_amount * rate
        total = calc_total(view, st.tdb)
        v = [st.time, st.rel_time/3600, market, sell_eur, 0.0, old_amount, 0.0, 0.0, 0.0, cash+sell_eur, total, 0.0, reason]
        push!(st.tdb, v)
    end
end

function sell_all(st, view, markets)
    st.stopped = true
    for market in markets
        sell(st, view, market)
    end
end

function check(st, rp_table; prn=true)
    global MAX_TRADE, MIN_DROP, MIN_DROP_24
    local top_ratings
    # create view to db with the first st.index rows
    view = st.df[1:st.index, :]
    by_hour, by_day = overview(view)
    top_ratings=nothing

    # update rp_table
    rel_price_table(st.df, st.time, rp_table)

    # every hour
    if mod(st.index, 60) == 0 
        # println("==> hour")
        st.rdb=rating_table(view, 10000; filter=false)
        update_total(st, view, st.time)
        if st.index > DAYS*24*60
            perf = find_performance(view, st.tdb, st.time, st.rdb)
            if ! isnothing(perf)
                for row in eachrow(perf)
                    market = row.MARKET
                    if row.RATING < MAX_RATING 
                        if prn println("==> Sell: ", market) end
                        sell(st, view, market; reason="row.RATING < MAX_RATING")
                    end
                end
            end
        end
    end

    # every minute: buy and sell if required
    for row in eachrow(by_hour)
        market = row.MARKET
        if ! st.stopped && row.RISE_1h >= MAX_RISE 
            if st.index < DAYS*24*60 
                buy(st, view, rp_table, market, MAX_TRADE; reason="RISE_1h >= MAX_RISE")
            else
                rating = market_rating(st.rdb, market)
                if rating > MIN_RATING # || row.RISE_1h >= MAX_RISE 
                    cash=calc_cash(view,st.tdb)
                    if cash >= KEEP
                        buy(st, view, rp_table, market, MAX_TRADE; reason="rating > MIN_RATING")
                        cash=calc_cash(view,st.tdb)
                        if cash >= KEEP
                            if cash >= 0.5*MAX_TRADE && cash < MAX_TRADE
                                buy(st, view, rp_table, market, cash; reason="rating > MIN_RATING")
                            else
                                buy(st, view, rp_table, market, MAX_TRADE; reason="rating > MIN_RATING")
                            end
                        end
                    end
                end
            end            
        end
        if row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24
            sell(st, view, market; reason="row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24")
        end
    end

    # every INTERVAL hours: evaluate performance, sell and buy
    if mod(st.index, 60*INTERVAL) == 0 
        perf = find_performance(view, st.tdb, st.time, st.rdb)
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
                sell(st, view, market; reason="last(perf.PERF) < 1.0 "*string(round(last(perf.PERF),digits=3)))
                
                if st.index < DAYS*24*60 # rating calculation is only reliable after DAYS days
                    # markets = (perf.MARKET)
                    markets = (first(sort(rp_table, [:REL_PRIZE], rev=true),6)).MARKET
                else
                    markets = (top_ratings.MARKET)
                    if prn println(top_ratings) end
                end
                cash = calc_cash(view, st.tdb)
                amount_to_use = cash
                if cash >= MAX_TRADE
                    amount_to_use = MAX_TRADE
                end
                # println("==> ", markets)
                i = 1
                for market in markets   
                    flag = false
                    if st.index >= DAYS*24*60
                        rating = market_rating(st.rdb, market)
                        flag = rating > MIN_RATING 
                    else 
                        performance = rel_price(rp_table, market)
                        if performance > 1.01
                            flag = true
                        end
                        flag = true          
                    end
                    if ! st.stopped && flag && buy(st, view, rp_table, market, amount_to_use; force=true, reason="every 12h: time < 4d or rating_ >= rating(st.rdb, market)")
                        if prn println("Buying: ", market, " time: ", (st.rel_time)/3600) end
                        cash = calc_cash(view, st.tdb)
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
    top_ratings
end

function trade(st; n=0, prn=true)
    st.mode=INIT
    st.rdb = nothing
    top_ratings = nothing
    if n == 0
        n = size(st.df)[1]
    end
    st.tdb = trade_db(st, START_KAPITAL)

    rp_table = rel_price_table(st.df, st.time)
    view = st.df[1:st.index, :]
    for market in PREFER
        buy(st, view, rp_table, market, MAX_TRADE; reason="market in PREFER")
    end
    vec=Float64[]
    j = 0
    for i in st.wait:n
        check(st, rp_table; prn=prn)
        if ! st.stopped && i > 60*24*4 && last(st.tdb.TOTAL)/maximum(st.tdb.TOTAL[end-12:end]) < STOP_LIMIT
            st.stopped=true
            j=0
            println("STOP at ", (st.rel_time)/3600)
            markets = list_markets(st.tdb)
            view = st.df[1:st.index, :]
            println(overview(view))
            println(markets)
            sell_all(st, view, markets)
            # update_total(st, view, time)
        end
        if st.stopped
            if j > 60*24*1.5
                st.mode = MIXED
                 println("START at ", (st.rel_time)/3600)
            end
            j += 1
        end
        st.index += 1
    end
    st.index -= 1
    st.tdb
end

function main(st)
    by_hour, by_day = overview(st.df)
    println(by_hour)
    println(by_day)
end

include("constants.jl")
include("basic.jl")
include("rel_prices.jl")
include("performance.jl")
include("trade_db.jl")

include("utils.jl")
include("tests.jl")
include("plotting.jl")
include("logging.jl")

st = State(read_log(logfiles()))
main(st)

# p1 = plot(df.BTC_EUR, label="BTC_EUR")
