function trade_db(st, save_eur::Float64)
    # time, market, sell_eur, buy_eur, sell_coins, buy_coins, save_eur, withdraw_eur, cash, total, reason
    st.index = st.wait
    trade_db = DataFrame(TIME=st.t0, REL_TIME=0.0, MARKET = "DEPOSIT", SELL_EUR=0.0, BUY_EUR=0.0, SELL_COINS=0.0, BUY_COINS=0.0, SAVE_EUR=save_eur, WITHDRAW_EUR=0.0, CASH=save_eur, TOTAL=save_eur, MEAN_RATING=0.0, REASON="save_eur")
end

function update_total(st, view, time)
    total = calc_total(view, st.tdb)
    rating_tab = rating_table(st, view, 10000; filter=false, extra_rating=true)
    top_ratings = (first(sort(rating_tab, [:RATING], rev=true), 8).RATING)
    mean_rating = mean(top_ratings)
    v = [time, (time-st.t0)/3600, "", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, calc_cash(st.tdb), total, mean_rating, "update_total"]
    push!(st.tdb, v)    
end