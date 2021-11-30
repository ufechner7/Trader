PREDICT = 24   # number of hours to predict
MINRISE = 10.0 # min rise over PREDICT hours to trigger buying 
MARKETS = ["LTO_EUR"]

function create_training_db(st)
    df = nothing
    for st.index in 1:(size(st.df)[1] - PREDICT*60)
        view = st.df[1:st.index, :]
        future_view = st.df[st.index+1:st.index + PREDICT*60-1, :]
        for market in MARKETS
            # println(market)
            time = view.TIME[st.index]
            rise1h = rise_1h(view, market)
            rise24h = rise_24h(view, market)
            future_rise24h = future_view[!, market][end] - future_view[!, market][1]
            buy = future_rise24h > MINRISE
            if isnothing(df)
                df = DataFrame(TIME=time, MARKET=market, RISE_1h=rise1h, RISE_24h=rise24h, FUTURE_RISE_24=future_rise24h, BUY=buy)
            else
                v = [time, market, rise1h, rise24h, future_rise24h, buy]
                push!(df, v) 
            end
            
        end
        if mod(st.index, 60) == 0
            print(".")
        end
    end
    return df
end
