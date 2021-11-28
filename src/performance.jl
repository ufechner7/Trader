function subrating(df, n, interest_function)
    markets = names(df)[2:end]
    interest = Float64[]
    deviance1 = Float64[]
    delta = Float64[]
    view = last(df, n)
    delta_t = view.TIME[end]-view.TIME[1] # timespan in seconds
    for market in markets
        y = view[!, market] 
        x = view.TIME .- view.TIME[1]
        X = [ones(n) x]
        y_rel = y./y[1]*100.0
        x = X[:,2]
        model = GLM.fit(LinearModel, X, y_rel, dropcollinear=true)
        b = GLM.coef(model)[1]
        beta = GLM.coef(model)[2]
        dev  = deviance(model)/n
        current_course = df[!, market]
        # plot(X[:,2], y_rel)
        # plot(X[:,2], predict(model))
        # (current_course - predicted_course)/predicted_course*100.0
        delta_y = y_rel[end] - (b + (beta * x[end])) 
        push!(interest, interest_function(beta * delta_t, delta_t))
        push!(deviance1, dev)
        push!(delta, delta_y)
    end
    return interest, deviance1, delta
end

function rating_table(df, m=8; filter=true)
    n = min(60*24*4, size(df)[1])
    # create view on the last four days or less, if less than 4 days of data available
    interest_4d, deviance_4d, delta_4d = subrating(df, n, weekly_interest)
    # create view on the last day or less, if less than 1 day of data available
    n = min(60*24, size(df)[1])
    interest_1d, deviance_1d, delta_1d = subrating(df, n, weekly_interest)
    interest_1d = min.(100000.0, interest_1d)
    markets = names(df)[2:end]
    rating2 = 100*(interest_4d./max.(deviance_4d, 10.0)./10.0 .+ 0.00.*interest_1d./max.(deviance_1d, 10.0))
    final_rating = 4*(interest_4d./(3.162.*sqrt.(max.(deviance_4d, 10.0)./10)) .+ 0.00.*interest_1d./max.(deviance_1d, 10.0))
    for i in 1:length(final_rating)
        if interest_1d[i] < -60.0
            # final_rating[i] = -100.0
        end
    end
    res = DataFrame(MARKET = markets, MONTHLY_INTEREST_4d = interest_4d, DEVIANCE_4d = deviance_4d, DELTA_4d = delta_4d, WEEKLY_INTEREST_1d = interest_1d, DEVIANCE_1d = deviance_1d, DELTA_1d = delta_1d, RATING=final_rating, RATING2=rating2)
    if filter
         filter!(row -> row.DELTA_4d > 0.0, res)
    end
    return first(sort!(res, [:RATING], rev=true), m)
end

function market_rating(rating_table, market)
    for row in eachrow(rating_table)
        if row.MARKET == market
            return row.RATING
        end
    end
end

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
        rating = 0.0
        if initial > 0.001 && total > 0.001
            performance = total / initial
            if ! isnothing(rating_table)
                rating = market_rating(rating_table, market)
                if isnothing(rating)
                    rating=-1.0
                end
            end
            rel_time=(time-view.TIME[1])/3600.0
            if isnothing(perf)
                perf = DataFrame(TIME=time, REL_TIME=rel_time, MARKET = market, PERF=performance, RATING=rating)
            else
                v = [time, rel_time, market, performance, rating]
                push!(perf, v)
            end
        end
    end
    return perf
end

function find_performance2(view, tdb, time, rating_table=nothing)
end