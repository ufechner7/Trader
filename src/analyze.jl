using CSV, DataFrames, Plotly, Dates, TimeZones, Impute

logfiles=["log_1637352719.csv","log_1637489560.csv"]
INDEX = 1
MAX_TRADE = 100.0 # max EUR per trade when buying
FEE = 1.0 - 0.45/100.0 # 0.45% fee per trade (0.25 fee, 0.2% spread)

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

function read_log()
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
    global INDEX
    t0 = first(df.TIME)
    INDEX=1
    trade_db = DataFrame(TIME=t0, MARKET = "DEPOSIT", SELL_EUR=0.0, BUY_EUR=0.0, SELL_COINS=0.0, BUY_COINS=0.0, SAVE_EUR=save_eur, WITHDRAW_EUR=0.0, TOTAL=save_eur)
end

function calc_cash(df, tdb)
    cash = 0.0
    for row in eachrow(tdb)
        market1 = row.MARKET
        if market1=="DEPOSIT"
            cash += row.SAVE_EUR - row.WITHDRAW_EUR
        else
            rate1 = last(df[!, market1])
            cash -= (row.BUY_EUR - row.SELL_EUR)
        end
    end    
    cash
end

function calc_total(df, tdb)
    total = 0.0
    for row in eachrow(tdb)
        market = row.MARKET
        if market=="DEPOSIT"
            total+=row.SAVE_EUR - row.WITHDRAW_EUR
        else
            rate = last(df[!, market])
            total+=(row.BUY_COINS - row.SELL_COINS) * rate
        end
    end
    return total
end

function buy(df, tdb, time, market, amount)
    global FEE
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_EUR) - sum(subset.SELL_EUR)
    cash = calc_cash(df, tdb)
    if old_amount < 0.01 && cash >= amount
        rate = last(df[!, market])

        println("Buy: ", market, " rate: ", rate)
        coins = amount / rate * FEE
        total = calc_total(df, tdb) - amount + coins * rate
        v = [time, market, 0.0, amount, 0.0, coins, 0.0, 0.0, total]
        push!(tdb, v)
    end
end

# sell all coins of a given market
function sell(df, tdb, time, market)
    subset = filter(row -> row.MARKET == market, tdb)
    old_amount = sum(subset.BUY_COINS) - sum(subset.SELL_COINS)
    rate = last(df[!, market])
    println("Sell: ", market, " coins: ", old_amount, " rate: ", rate)
    sell_eur = old_amount * rate
    total = calc_total(df, tdb) + sell_eur
    v = [time, market, sell_eur, 0.0, old_amount, 0.0, 0.0, 0.0, total]
    push!(tdb, v)
end

function sell_all(df, tdb)
    markets = ["MLN_EUR", "ALICE_EUR"]
    time = last(df.TIME)
    for market in markets
        sell(df, tdb, time, market)
    end
end

function check(df, tdb)
    global INDEX, MAX_TRADE
    # create view to db with the first INDEX rows
    view = df[1:INDEX, :]
    by_hour, by_day = overview(view)
    # println(by_hour[1,:])
    for row in eachrow(by_hour)
        if row.RISE_1h >= 5.0
            market = row.MARKET
            time = df.TIME[INDEX] + 10          
            buy(view, tdb, time, market, MAX_TRADE)
        end
    end
    INDEX+=1
end

function trade(df, n=0)
    if n == 0
        n = size(df)[1]
    end
    tdb = trade_db(df, 1000.0)
    for i in 1:n
        check(df, tdb)
    end
    tdb
end

df = read_log()
if true
    by_hour, by_day = overview(df)
    println(by_hour)
    println(by_day)
else
    trade(df, 1000)
end

# create trade data base
# tdb = trade_db(df, 1000.0)
# check(df, tdb)
# p1 = plot(df.BTC_EUR, label="BTC_EUR")
