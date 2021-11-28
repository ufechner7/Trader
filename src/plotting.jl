function list_markets(tdb, all=false)
    markets=String[]
    final_markets=String[]
    for row in eachrow(tdb)
        market = row.MARKET
        if market!="DEPOSIT" && !(market in markets) && market !=""
            push!(markets, market)
        end
    end
    if all
        return markets
    end
    for market in markets
        subset = filter(row -> row.MARKET == market, tdb)
        if sum(subset.BUY_COINS) - sum(subset.SELL_COINS) > 0.001
            push!(final_markets, market)
        end
    end
    final_markets
end

function get_tdb(st)
    if isnothing(st.tdb)
        tdb = trade(st; prn=false)
        st.tdb=tdb
    else
        tdb=st.tdb
    end
    tdb
end

function plot_1h(st, name)
    col     = st.df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    plot(window, label=name)
    nothing
end

function plot_24h(st, name)
    col     = st.df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    plot(window, label=name)
    nothing
end

function plot_total(st)
    tdb=get_tdb(st)
    figure()
    xlabel("time [h]" * "               last_updated: " * last_updated(st.df))
    ylabel("EUR")
    plot((tdb.TIME .- st.t0)./3600, tdb.TOTAL, label="total")
    plot((tdb.TIME .- st.t0)./3600, tdb.CASH, label="cash")
    title("Value of total assets")
    grid("on")
    legend(loc="lower right")
    nothing
end

function plot_interest(st)
    tdb = get_tdb(st)
    markets = list_markets(tdb)
    sell_all(st, st.df, markets)
    interest = ((tdb.TOTAL)./first(tdb.TOTAL).-1.0).*100.0
    duration = (tdb.TIME) .- first(tdb.TIME)
    monthly = monthly_interest.(interest, duration)
    figure()
    ax = plt.gca()
    ax.set_ylim([0, 600])
    ax.set_xlim([80, (last(tdb.TIME)-st.t0)/3600])
    xlabel("time [h]" * "               last_updated: " * last_updated(st.df))
    plot((tdb.TIME .- st.t0)./3600, monthly)
    title("Monthly interest [%]\n")
    grid("on")
    nothing
end

function plot_rating(st)
    tdb = get_tdb(st)
    y = tdb[tdb.MARKET .== "", :MEAN_RATING]
    x = tdb[tdb.MARKET .== "", :TIME]
    figure()
    plot((x[96:end] .- st.t0)./3600, y[96:end])
    title("Hourly mean performance of top markets")
    grid("on")
    nothing
end

function plot_markets(st)
    tdb = get_tdb(st)
    if length(st.markets) == 0
        st.markets = list_markets(tdb, true)
    end
    x = (st.df.TIME .- st.t0)./360
    figure()
    xlabel("time [h]")
    ylabel("performance [%]")
    # stackplot(x,y1, y2, y3, labels=['A','B','C'])
    for market in st.markets
        println(market)
        ref = first(st.df[!, market])
        y=((st.df[!, market]/ref).-1.0) .* 100.0
        plot(x, y, label = market)
    end
    legend(loc="upper left")
    grid("on")
    nothing
end

function plot_stacked(st)
    tdb = get_tdb()
    if isnothing(markets)
        markets = list_markets(tdb, true)
    end
    x=(st.df.TIME .- T0)./360
end