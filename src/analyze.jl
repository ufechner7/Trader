using CSV, DataFrames, Plotly, Dates, TimeZones, Impute, Statistics

LOGFILES = ["log_1637352719.csv","log_1637489560.csv","log_1637573477.csv","log_1637607862.csv"]
PREFER   = ["AVAX_EUR", "SAND_EUR","VGX_EUR"]
INDEX = 1
START_KAPITAL = 1000.0           # in EUR
MAX_TRADE     = 140.0            # max EUR per trade when buying
FEE           = 1.0 - 0.45/100.0 # 0.45% fee per trade (0.25 fee, 0.2% spread)
MAX_RISE      =  4.3             # buy  if RISE_1h goes above this value [%]
MIN_DROP      = -25.0            # sell if DROP_1h goes below this value [%]
MIN_DROP_24   = -35.0            # sell if DROP_24h goes below this value [%]
WAIT          = 60               # number of minutes to wait before dealing
T0            = 0

# fetch the latest log file from the server
function fetch_log()
    mycommand = `./fetch_log.sh`
    run(mycommand)
end

function seconds2human(delta)
    hours = div(delta, 3600)
    reminder = mod(delta, 3600)
    minutes = div(reminder, 60)
    seconds = mod(reminder, 60) 
    return Dates.Hour(hours) + Dates.Minute(minutes) + Dates.Second(seconds)
end

function read_log(logfiles)
    df = nothing
    t_end = 0
    for logfile in logfiles
        df_new = CSV.read("data/" * logfile, DataFrame)
        if isnothing(df)
            df=df_new
            t_end = last(df.TIME)
        else
            t_start = first(df_new.TIME)
            if (t_start - t_end) > 60
               n = div(t_start - t_end + 30, 60)
               v = fill(missing, size(df)[2]-1)
               println("Missing: ", n, " minutes") 
               allowmissing!(df)
               for i in 1:n
                   v1 = vcat([i*60+t_end], v)
                   push!(df, v1)
               end
            end
            df = outerjoin(df, df_new, matchmissing=:equal, on = intersect(names(df),  names(df_new)))
            t_end = last(df.TIME)
        end
    end
    df = Impute.interp(df)
    disallowmissing!(df)

    new_names=Symbol[]
    i = 1
    for header in names(df)
        push!(new_names, Symbol(replace(header, "-" => "_")))
    end
    rename!(df, new_names)
    data_length = last(df.TIME) - first(df.TIME)
    utc_time = unix2datetime(last(df.TIME))
    local_time = ZonedDateTime(utc_time, TimeZone("Europe/Amsterdam"); from_utc=true) 
    println("Duration:   ", seconds2human(data_length))
    println("Last entry: ", local_time, "\n")
    return df
end

function change_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function drop_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    max1     = maximum(window)
    current = last(col)
    drop = (current/max1 - 1.0) * 100.0
end

function drop_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    max1     = maximum(window)
    current = last(col)
    drop = (current/max1 - 1.0) * 100.0
end

function plot_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    plot(window, label=name)
end

function plot_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    plot(window, label=name)
end

function change_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function overview(df)
    CHANGES_1h = Float64[]
    CHANGES_24h = Float64[]
    DROP_1h = Float64[]
    DROP_24h = Float64[]
    for name in names(df)
        push!(CHANGES_1h,  change_1h(df, Symbol(name)))
        push!(CHANGES_24h, change_24h(df, Symbol(name)))
        push!(DROP_1h, drop_1h(df, Symbol(name)))
        push!(DROP_24h, drop_24h(df, Symbol(name)))
    end
    res = DataFrame(MARKET = names(df), RISE_1h = CHANGES_1h, DROP_1h = DROP_1h, RISE_24h = CHANGES_24h, DROP_24h = DROP_24h)
    delete!(res, 1) # delete time entry
    res_hour = sort!(res, [:RISE_1h, :RISE_24h], rev=true)
    by_hour = first(res_hour, 8)
    res_day = sort!(res, [:RISE_24h, :RISE_1h], rev=true)
    by_day  = first(res_day, 8)
    return by_hour, by_day
end

function trade_db(df, save_eur::Float64)
    # time, market, sell_eur, buy_eur, sell_coins, buy_coins, save_eur, withdraw_eur, total
    global INDEX, T0, WAIT
    t0 = first(df.TIME)
    INDEX = WAIT
    T0 = t0
    trade_db = DataFrame(TIME=t0, REL_TIME=0, MARKET = "DEPOSIT", SELL_EUR=0.0, BUY_EUR=0.0, SELL_COINS=0.0, BUY_COINS=0.0, SAVE_EUR=save_eur, WITHDRAW_EUR=0.0, CASH=save_eur, TOTAL=save_eur)
end

function calc_cash(df, tdb)
    cash = 0.0
    for row in eachrow(tdb)
        market1 = row.MARKET
        if market1=="DEPOSIT"
            cash += row.SAVE_EUR - row.WITHDRAW_EUR
        elseif market1 != ""
            rate1 = last(df[!, market1])
            cash -= (row.BUY_EUR - row.SELL_EUR)
        end
    end    
    cash
end

function calc_total(df, tdb)
    total = last(tdb.CASH)
    for row in eachrow(tdb)
        market = row.MARKET
        if market!="DEPOSIT" && market != ""
            rate = last(df[!, market])
            total+=(row.BUY_COINS - row.SELL_COINS) * rate
        end
    end
    return total
end

function buy(df, tdb, time, market, amount, force=false)
    global FEE, T0
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_EUR) - sum(subset.SELL_EUR)
    cash = calc_cash(df, tdb)
    if (old_amount < 0.01 || force) && cash >= amount
        rate = last(df[!, market])
        coins = amount / rate * FEE
        total = calc_total(df, tdb) + coins * rate - amount
        v = [time, time-T0, market, 0.0, amount, 0.0, coins, 0.0, 0.0, cash-amount, total]
        push!(tdb, v)
    end
end

function update_total(df, tdb, time)
    global T0
    total = calc_total(df, tdb)
    v = [time, time-T0, "", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, calc_cash(df, tdb), total]
    push!(tdb, v)    
end

# sell all coins of a given market
function sell(df, tdb, time, market)
    global T0
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_COINS) - sum(subset.SELL_COINS)
    cash = calc_cash(df, tdb)
    if old_amount > 0.01
        rate = last(df[!, market])
        # println("Sell: ", market, " rate: ", rate)
        sell_eur = old_amount * rate
        total = calc_total(df, tdb)
        v = [time, time-T0, market, sell_eur, 0.0, old_amount, 0.0, 0.0, 0.0, cash+sell_eur, total]
        push!(tdb, v)
    end
end

function list_markets(tdb)
    markets=String[]
    final_markets=String[]
    for row in eachrow(tdb)
        market = row.MARKET
        if market!="DEPOSIT" && !(market in markets) && market !=""
            push!(markets, market)
        end
    end
    for market in markets
        subset = filter(row -> row.MARKET == market, tdb)
        if sum(subset.BUY_COINS) - sum(subset.SELL_COINS) > 0.001
            push!(final_markets, market)
        end
    end
    final_markets
end

function sell_all(df, tdb, markets)
    time = last(df.TIME)
    for market in markets
        sell(df, tdb, time, market)
    end
end

function find_performance(view, tdb, time)
    perf = nothing
    dict = nothing
    for row in eachrow(tdb)
        total = 0.0
        initial = 0.0
        market = row.MARKET
        if market!="DEPOSIT" && market != ""
            rate = last(view[!, market])
            initial += row.BUY_EUR
            total+=(row.BUY_COINS - row.SELL_COINS) * rate
        end
        if isnothing(dict)
            dict = Dict(market => (initial, total))
        else
            if haskey(dict, market)
                ini,tot = dict[market]
                dict[market] = (ini + initial, tot +  total)
            else
                dict[market] = (initial, total)
            end
        end
    end
    for market in collect(keys(dict))
        initial, total = dict[market]
        if initial > 0.001 && total > 0.001
            performance = total / initial
            if isnothing(perf)
                perf = DataFrame(TIME=time, MARKET = market, PERF=performance)
            else
                v = [time, market, performance]
                push!(perf, v)
            end
        end
    end
    return perf
end

function check(df, tdb, prn=true)
    global INDEX, MAX_TRADE, MIN_DROP, MIN_DROP_24
    # create view to db with the first INDEX rows
    view = df[1:INDEX, :]
    by_hour, by_day = overview(view)
    for row in eachrow(by_hour)
        market = row.MARKET
        time = df.TIME[INDEX] + 10 
        if row.RISE_1h >= MAX_RISE && row.DROP_1h == 0.0 && row.RISE_1h < MAX_RISE + 3.0
            buy(view, tdb, time, market, MAX_TRADE)
        end
        if row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24
            sell(df, tdb, time, market)
        end

    end
    if mod(INDEX, 60) == 0 # every hour
        time = df.TIME[INDEX]
        update_total(view, tdb, time)
    end
    if mod(INDEX, 60*12) == 0 # every 12h
        time = df.TIME[INDEX]
        perf = find_performance(view, tdb, time)
        if ! isnothing(perf)
            sort!(perf, [:PERF], rev=true)
            if prn println(perf) end
            market = last(perf.MARKET)
            if ( !(market in PREFER) && last(perf.PERF) < 1.0) || ((market in PREFER) && last(perf.PERF) < 0.95)
                if prn println("Selling: ", market) end
                sell(view, tdb, time, market)
                market = first(perf.MARKET)
                if first(perf.PERF) > 1.0
                    if prn println("Buying: ", market, " time: ", time) end
                    cash = calc_cash(view, tdb)
                    if cash >= MAX_TRADE
                        buy(view, tdb, time, market, MAX_TRADE, true)
                    else
                        buy(view, tdb, time, market, cash, true)
                    end
                end
            end
        end
    end
    INDEX+=1
end

function trade(df, n=0, prn=true)
    if n == 0
        n = size(df)[1]
    end
    tdb = trade_db(df, START_KAPITAL)
    time = df.TIME[INDEX] + 10 
    view = df[1:INDEX, :]
    for market in PREFER
        buy(view, tdb, time, market, MAX_TRADE)
    end
    for i in WAIT:n
        check(df, tdb, prn)
    end
    tdb
end

# interest in percent, duration in seconds
function yearly_interest(interest, duration)
    days=duration/(24*3600)
    years=days/365.0
    intervalls_per_year = 1.0/years
    return 100.0*((1 + interest/100.0)^intervalls_per_year - 1.0)
end

# interest in percent, duration in seconds
function monthly_interest(interest, duration)
    days=duration/(24*3600)
    months=days/30.416666666666668
    intervalls_per_month = 1.0/months
    return 100.0*((1 + interest/100.0)^intervalls_per_month - 1.0)
end

function test1(df)
    markets = ["MLN_EUR"]
    tdb=trade(df, 30)
    view = df[1:INDEX, :]
    sell_all(view, tdb, markets)
    tdb
end

function test2(df)
    markets = ["MLN_EUR", "ALICE_EUR"]
    tdb=trade(df, 60)
    view = df[1:INDEX, :]
    sell_all(view, tdb, markets)
    tdb
end

function test3(df, plot=false)
    tdb=trade(df)
    markets = list_markets(tdb)
    sell_all(df, tdb, markets)

    if plot
        push!(markets, "BTC_EUR")
        return plot_markets(df, tdb, markets)
    else
        tdb2 = filter(row -> row.MARKET != "", tdb)
        interest = (last(tdb.TOTAL)/first(tdb.TOTAL)-1.0)*100.0
        duration = last(df.TIME) - first(df.TIME)
        yearly = yearly_interest(interest, duration)
        monthly = monthly_interest(interest, duration)
        # println("The interest rate per year is:  ", round(yearly), " %")
        println("The interest rate per month is: ", round(monthly), " %")
        return tdb2
    end
end

function plot_markets(df, tdb, markets)
    global T0
    p1 = nothing
    i=1
    traces=GenericTrace{Dict{Symbol, Any}}[]
    for market in markets
        ref = first(df[!, market])
        trace = scatter(
            x=df.TIME .- T0,
            y=df[!, markets[i]]/ref,
            name = markets[i],
        )
        push!(traces, trace)
        i+=1
    end
    p1 = plot(traces)
    p1
end

function test4(df)
    tdb=trade(df)
    markets = list_markets(tdb)
    plot_markets(df, tdb, markets)
end

function test5(df)
    global WAIT
    totals = Float64[]
    for i in 1:46
        WAIT = i*60
        tdb=trade(df, 0, false)
        push!(totals, last(tdb.TOTAL))
        println(last(tdb.TOTAL))
    end
    av = mean(totals)
    println("Avarage interest: ", (av/1000.0-1.0)*100.0, " %")
    totals
end

function test_merge()
   logfiles = LOGFILES[1:3]
   df = read_log(logfiles)
   plot(df.TIME)
end

function plot_total(df)
    tdb = trade(df, 0, false)
    plot(tdb.TIME, tdb.TOTAL)
end

df = read_log(LOGFILES)
if true
    by_hour, by_day = overview(df)
    println(by_hour)
    println(by_day)
else
    tdb=test3(df)
    plot_total(tdb)
end

# p1 = plot(df.BTC_EUR, label="BTC_EUR")
