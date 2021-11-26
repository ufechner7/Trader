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
    global TDB
    if isnothing(TDB)
        tdb = trade(df, 0)
        TDB=tdb
    else
        tdb=TDB
    end
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

function test3b(df, plot=false)
    global WAIT, TDB
    WAIT = 4*60
    if isnothing(TDB)
        tdb = trade(df, 0)
        TDB=tdb
    else
        tdb=TDB
    end
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
    WAIT=60
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
   logfiles = LOGFILES["". ""]
   df = read_log(logfiles)
   plot(df.TIME)
end