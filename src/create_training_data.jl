PREDICT = 24   # number of hours to predict
MINRISE = 10.0 # min rise over PREDICT hours to trigger buying 
MARKETS = ["LTO_EUR"]

function append_td(df, time, market, rise1h, rise24h, future_rise24h, buy)
end

function create_training_db(st)
    df = DataFrame()
    for st.index in 1:(size(st.df)[1] - PREDICT*60)
        view = st.df[1:st.index, :]
        future_view = st.df[st.index+1:st.index + PREDICT*60-1, :]
        for market in MARKETS
            # println(market)
            time = view.TIME
            rise1h = rise_1h(view, market)
            rise24h = rise_24h(view, market)
            future_rise24h = future_view[!, market][end] - future_view[!, market][1]
            buy = future_rise24h > MINRISE
            append_td(df, time, market, rise1h, rise24h, future_rise24h, buy)

        end
        if mod(st.index, 60) == 0
            print(".")
        end
    end
end
