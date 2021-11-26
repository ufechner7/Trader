function find_performance(view, tdb, time, rating_table=nothing)
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
        rating_ = 0.0
        if initial > 0.001 && total > 0.001
            performance = total / initial
            if ! isnothing(rating_table)
                rating_ = rating(rating_table, market)
                if isnothing(rating_)
                    rating_=-1.0
                end
            end
            rel_time=(time-T0)/3600.0
            if isnothing(perf)
                perf = DataFrame(TIME=time, REL_TIME=rel_time, MARKET = market, PERF=performance, RATING=rating_)
            else
                v = [time, rel_time, market, performance, rating_]
                push!(perf, v)
            end
        end
    end
    return perf
end