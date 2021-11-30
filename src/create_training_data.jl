PREDICT = 24   # number of hours to predict
MINRISE = 10.0 # min rise over PREDICT hours to trigger buying 
MARKETS = ["LTO_EUR","AVAX_EUR","ATA_EUR","CHR_EUR","MANA_EUR","SAND_EUR", "ALICE_EUR", "ROSE_EUR", "LRC_EUR", "SHIB_EUR", "COTI_EUR", "DOT_EUR"]

# TODO split the data in real and fake data (good and bad data sets)

using JLD2, DataFrames

function create_training_db(st)
    df = nothing
    for st.index in 60:(size(st.df)[1] - PREDICT*60)
        view = st.df[1:st.index, :]
        future_view = st.df[st.index+1:st.index + PREDICT*60-1, :]
        markets = first(names(st.df)[2:end], 30)
        for market in markets
            # println(market)
            time = view.TIME[st.index]
            rise1h = rise_1h(view, market)
            rise24h = rise_24h(view, market)
            future_rise24h = ((future_view[!, market][end] / future_view[!, market][1]) - 1.0) * 100.0
            buy = future_rise24h > MINRISE
            if isnothing(df)
                df = DataFrame(TIME=time, MARKET=market, RISE_1h=Float64(rise1h), RISE_24h=Float64(rise24h), FUTURE_RISE_24=Float64(future_rise24h), BUY=buy)
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

function save_training_db(db)
    jldsave("training_db.jld2"; db)
end

function load_training_db()
    load_object("training_db.jld2")
end
