function test1(st)
    markets = ["MLN_EUR"]
    st.tdb=trade(st, n=30)
    view = st.df[1:st.index, :]
    sell_all(st, markets; reason="final sails")
    st.tdb
end

function test2(st)
    markets = ["MLN_EUR", "ALICE_EUR"]
    st.tdb=trade(st, n=60)
    view = st.df[1:st.index, :]
    sell_all(st, st.df, markets; reason="final sails")
    st.tdb
end

function test3(st; plot=false, prn=false)
    tdb=get_tdb(st)
    markets = list_markets(tdb)
    sell_all(st, st.df, markets; reason="final sails")

    if plot
        push!(markets, "BTC_EUR")
        return plot_markets(st)
    else
        tdb2 = filter(row -> row.MARKET != "", tdb)
        interest = (last(tdb.TOTAL)/first(tdb.TOTAL)-1.0)*100.0
        duration = last(st.df.TIME) - first(st.df.TIME)
        yearly = yearly_interest(interest, duration)
        monthly = monthly_interest(interest, duration)
        # println("The interest rate per year is:  ", round(yearly), " %")
        println("The interest rate per month is: ", round(monthly), " %")
        return tdb2
    end
end

function test3b(st; plot=false)
    st.wait = 4*60
    tdb = get_tdb(st)
    markets = list_markets(tdb)
    sell_all(st, st.df, markets; reason="final sails")
 
    tdb2 = filter(row -> row.MARKET != "", tdb)
    interest = (last(tdb.TOTAL)/first(tdb.TOTAL)-1.0)*100.0
    duration = last(st.df.TIME) - first(st.df.TIME)
    yearly = yearly_interest(interest, duration)
    monthly = monthly_interest(interest, duration)
    # println("The interest rate per year is:  ", round(yearly), " %")
    println("The interest rate per month is: ", round(monthly), " %")
    return tdb2

    st.wait = 60
end

function test4(st)
    tdb=trade(st)
    markets = list_markets(tdb)
    plot_markets(st.df)
end

function test5(st)
    global WAIT
    totals = Float64[]
    for i in 1:46
        WAIT = i*60
        tdb=trade(st, prn=false)
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