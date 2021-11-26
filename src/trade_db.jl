function trade_db(df, save_eur::Float64)
    # time, market, sell_eur, buy_eur, sell_coins, buy_coins, save_eur, withdraw_eur, cash, total, reason
    global INDEX, T0, WAIT
    t0 = first(df.TIME)
    INDEX = WAIT
    T0 = t0
    trade_db = DataFrame(TIME=t0, REL_TIME=0.0, MARKET = "DEPOSIT", SELL_EUR=0.0, BUY_EUR=0.0, SELL_COINS=0.0, BUY_COINS=0.0, SAVE_EUR=save_eur, WITHDRAW_EUR=0.0, CASH=save_eur, TOTAL=save_eur, MEAN_RATING=0.0, REASON="save_eur")
end

function update_total(df, tdb, time)
    global T0
    total = calc_total(df, tdb)
    RATING_TAB = rating_table(df, 10000; filter=false)
    top_ratings = (first(sort(RATING_TAB, [:RATING], rev=true), 8).RATING)
    mean_rating = mean(top_ratings)
    v = [time, time-T0, "", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, calc_cash(df, tdb), total, mean_rating, "update_total"]
    push!(tdb, v)    
end