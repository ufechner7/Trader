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

function get_tdb()
    global TDB
    if isnothing(TDB)
        tdb = trade(df; prn=false)
        TDB=tdb
    else
        tdb=TDB
    end
    tdb
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

function plot_total(df)
    figure()
    tdb=get_tdb()
    xlabel("time [h]" * "               last_updated: " * last_updated(df))
    ylabel("EUR")
    plot((tdb.TIME.-T0)./3600, tdb.TOTAL, label="total")
    plot((tdb.TIME.-T0)./3600, tdb.CASH, label="cash")
    title("Value of total assets")
    grid("on")
    legend(loc="lower right")
    nothing
end

function plot_interest(df)
    figure()
    tdb = get_tdb()
    markets = list_markets(tdb)
    sell_all(df, tdb, markets)
    interest = ((tdb.TOTAL)./first(tdb.TOTAL).-1.0).*100.0
    duration = (tdb.TIME) .- first(tdb.TIME)
    monthly = monthly_interest.(interest, duration)
    ax = plt.gca()
    ax.set_ylim([0, 600])
    ax.set_xlim([80, (last(tdb.TIME)-T0)/3600])
    xlabel("time [h]" * "               last_updated: " * last_updated(df))
    plot((tdb.TIME.-T0)./3600, monthly)
    title("Monthly interest [%]\n")
    grid("on")
    nothing
end

function plot_rating(df)
    figure()
    tdb = get_tdb()
    y = TDB[TDB.MARKET .== "", :MEAN_RATING]
    x = TDB[TDB.MARKET .== "", :TIME]
    plot((x[96:end].-T0)./3600, y[96:end])
    title("Hourly mean performance of top markets")
    grid("on")
    nothing
end

function plot_markets(df, tdb=nothing, markets=nothing)
    tdb = get_tdb()
    if isnothing(markets)
        markets = list_markets(tdb, true)
    end
    x=(df.TIME .- T0)./360
    xlabel("time [h]")
    ylabel("performance [%]")
    # stackplot(x,y1, y2, y3, labels=['A','B','C'])
    for market in markets
        ref = first(df[!, market])
        y=((df[!, market]/ref).-1.0) .* 100.0
        plot(x, y, label = market)
    end
    legend(loc="upper left")
    grid("on")
    nothing
end

function plot_stacked(df, tdb=nothing)
    tdb = get_tdb()
    if isnothing(markets)
        markets = list_markets(tdb, true)
    end
    x=(df.TIME .- T0)./360
end