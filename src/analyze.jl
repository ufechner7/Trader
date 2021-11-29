using CSV, DataFrames, PyPlot, Dates, TimeZones, Impute, Statistics, GLM, Parameters

function buy(st, view, rp_table, market, amount; force=false, reason="")
    subset = filter(row -> row.MARKET == market, st.tdb)
    old_amount = sum(subset.BUY_EUR) - sum(subset.SELL_EUR)
    cash = st.cash
    if (old_amount < 0.01 || force && old_amount <= MAX_TRADE + 0.01) && cash >= amount
        rate = last(view[!, market])
        coins = amount / rate * FEE
        total = calc_total(view, st.tdb) + coins * rate - amount
        v = [st.time, st.rel_time/3600, market, 0.0, amount, 0.0, coins, 0.0, 0.0, cash-amount, total, 0.0, reason]
        rel_price_table(view, time, rp_table; ref_market=market)
        push!(st.tdb, v)
        st.cash -= amount
        return true
    end
    return false
end

# sell all coins of a given market
function sell(st, view, market; reason="")
    subset = filter(row -> row.MARKET == market, st.tdb)
    old_amount = sum(subset.BUY_COINS) - sum(subset.SELL_COINS)
    cash = st.cash
    if old_amount > 0.01
        rate = last(view[!, market])
        # println("Sell: ", market, " rate: ", rate)
        sell_eur = old_amount * rate
        total = calc_total(view, st.tdb)
        v = [st.time, st.rel_time/3600, market, sell_eur, 0.0, old_amount, 0.0, 0.0, 0.0, cash+sell_eur, total, 0.0, reason]
        push!(st.tdb, v)
        st.cash += sell_eur
    end
end

# sell all coins of a given list of markets
function sell_all(st, view, markets; reason="")
    st.stopped = true
    for market in markets
        sell(st, view, market; reason=reason)
    end
end



function trade(st; n=0, prn=true)
    st.mode = INIT
    st.rdb = nothing
    top_ratings = nothing
    if n == 0
        n = size(st.df)[1]
    end
    st.tdb = trade_db(st, START_KAPITAL)

    st.rp_table = rel_price_table(st.df, st.time)
    view = st.df[1:st.index, :]
    for market in PREFER
        buy(st, view, st.rp_table, market, MAX_TRADE; reason="market in PREFER")
    end
    vec=Float64[]
    j = 0
    for i in st.wait:n
        check(st; prn=prn)
        if ! st.stopped && i > 60*24*4 && last(st.tdb.TOTAL)/maximum(st.tdb.TOTAL[end-12:end]) < STOP_LIMIT
            st.stopped=true
            j=0
            println("STOP at ", (st.rel_time)/3600)
            markets = list_markets(st.tdb)
            view = st.df[1:st.index, :]
            println(overview(view))
            println(markets)
            sell_all(st, view, markets; reason="total falling > STOP_LIMIT")
            # update_total(st, view, time)
        end
        if st.stopped
            if j > 60*24*1.5
                if ALLOW_RATING
                    st.mode = MIXED
                else
                    st.mode = INIT
                end
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
include("check.jl")

include("utils.jl")
include("tests.jl")
include("plotting.jl")
include("logging.jl")

st = State(read_log(logfiles()))
main(st)

# p1 = plot(df.BTC_EUR, label="BTC_EUR")
