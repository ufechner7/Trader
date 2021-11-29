# the core rountine "check" that checks the courses and buys and sells
# helper functions on_minute, on_hour, on_some_hours

# helper function
function amount_to_use(st, view)
    cash = calc_cash(view, st.tdb)
    amount = cash
    if cash >= MAX_TRADE+KEEP
        amount = MAX_TRADE
    elseif cash > KEEP
        amount = cash - KEEP
    else
        amount = 0.0
    end
    amount
end

function on_minute(st, view, by_hour, prn)
    for row in eachrow(by_hour)
        market = row.MARKET
        if ! st.stopped && row.RISE_1h >= MAX_RISE 
            st.δ_rating[market]=EXTRA_RATING
            buy(st, view, st.rp_table, market, MAX_TRADE; reason="RISE_1h >= MAX_RISE")
        end
        if row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24
            sell(st, view, market; reason="row.DROP_1h < MIN_DROP || row.DROP_24h < MIN_DROP_24")
        end
    end
end

function on_hour(st, view, prn)
    st.rdb = rating_table(st, view, 10000; filter=false)
    update_total(st, view, st.time)
end

# every INTERVAL hours: evaluate performance during mode INIT, sell and buy
function on_some_hours_init(st, view, prn)
    perf = find_performance(view, st.tdb, st.time, st.rdb)
    top_ratings = rating_table(st, view, 8, filter=false) # not used for decision making
    
    if ! isnothing(perf)
        sort!(perf, [:PERF], rev=true)
        if prn println(perf) end
        market = last(perf.MARKET)
        
        if last(perf.PERF) < 1.0 && ! (market in (first(sort(st.rp_table, [:REL_PRIZE], rev=true), 2)).MARKET)
            # SELL 
            if prn println("Selling: ", market) end
            sell(st, view, market; reason="last(perf.PERF) < 1.0 " * string(round(last(perf.PERF),digits=3)))
            # BUY
             for market in (first(sort(st.rp_table, [:REL_PRIZE], rev=true), 2)).MARKET            
                if buy(st, view, st.rp_table, market, amount_to_use(st, view); force=true, reason="every 6h: mode==INIT)")
                    if prn println("Buying: ", market, " time: ", (st.rel_time)/3600) end
                    if calc_cash(view, st.tdb) < 0.5 * MAX_TRADE break end              
                end
            end
        end
    end
    return top_ratings
end

# every INTERVAL hours: evaluate performance when rating is available, sell and buy
function on_some_hours(st, view, prn)
    perf = find_performance(view, st.tdb, st.time, st.rdb)
    top_ratings = rating_table(st, view, 8; filter=false, extra_rating=true)
    
    if ! isnothing(perf)
        sort!(perf, [:PERF], rev=true)
        if prn println(perf) end
        market = last(perf.MARKET)
        
        best_markets = (first(sort(st.rp_table, [:REL_PRIZE], rev=true), 3)).MARKET
        if ! (market in best_markets)
            # SELL 
            if prn println("Selling: ", market) end
            sell(st, view, market; reason="not in best_markets" )
            
            # BUY
            if prn println(top_ratings) end
            for market in top_ratings.MARKET   
                flag =  market_rating(st.rdb, market) > MIN_RATING 
                if ! st.stopped && flag && buy(st, view, st.rp_table, market, amount_to_use(st, view); force=true, reason="every 12h: rating > MIN_RATING")
                    if prn println("Buying: ", market, " time: ", (st.rel_time)/3600) end
                    if calc_cash(view, st.tdb) < 0.5 * MAX_TRADE break end                      
                end
            end
        end
    end
    return top_ratings
end

function check(st; prn=true)
    top_ratings = nothing

    # create view to db with the first st.index rows
    view = st.df[1:st.index, :]
    by_hour, by_day = overview(view)

    # switch state if required
    if st.mode == INIT && st.index > DAYS*24*60 && ALLOW_RATING
        st.mode = RATING
    end

    # update rp_table
    rel_price_table(st.df, st.time, st.rp_table)

    # every hour
    if mod(st.index, 60) == 0 
        on_hour(st, view, prn)
    end

    # every minute: buy and sell if required
    on_minute(st, view, by_hour, prn)

    # every INTERVAL hours: evaluate performance, sell and buy
    if mod(st.index, 60*INTERVAL) == 0 
        if st.mode == INIT
            topratings = on_some_hours_init(st, view, prn)
        else
            topratings = on_some_hours(st, view, prn)
        end
    end
    top_ratings
end