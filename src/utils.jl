function seconds2human(delta)
    hours = div(delta, 3600)
    reminder = mod(delta, 3600)
    minutes = div(reminder, 60)
    seconds = mod(reminder, 60) 
    return Dates.Hour(hours) + Dates.Minute(minutes) + Dates.Second(seconds)
end

function calc_cash(df, tdb)
    cash = 0.0
    if isnothing(tdb)
        return START_KAPITAL
    end
    for row in eachrow(tdb)
        market1 = row.MARKET
        if market1=="DEPOSIT"
            cash += row.SAVE_EUR - row.WITHDRAW_EUR
        elseif market1 != ""
            rate1 = last(df[!, market1])
            cash -= (row.BUY_EUR - row.SELL_EUR)
        end
    end    
    cash
end

function calc_total(df, tdb)
    total = last(tdb.CASH)
    for row in eachrow(tdb)
        market = row.MARKET
        if market!="DEPOSIT" && market != ""
            rate = last(df[!, market])
            total+=(row.BUY_COINS - row.SELL_COINS) * rate
        end
    end
    return total
end

# interest in percent, duration in seconds
function yearly_interest(interest, duration)
    days=duration/(24*3600)
    years=days/365.0
    intervalls_per_year = 1.0/years
    return 100.0*((1 + interest/100.0)^intervalls_per_year - 1.0)
end

# interest in percent, duration in seconds
function monthly_interest(interest, duration)
    if interest < -100.0
        interest = -100.0
    end
    days=duration/(24*3600)
    months=days/30.416666666666668 
    intervalls_per_month = 1.0/months
    try
        return 100.0*((1 + interest/100.0)^intervalls_per_month - 1.0)
    catch e
        println("Error in monthly_interest. interest: ", interest)
    end
end

function weekly_interest(interest, duration)
    if interest < -100.0
        interest = -100.0
    end
    days=duration/(24*3600)
    weeks=days/7.0
    intervalls_per_week = 1.0/weeks
    return 100.0*((1 + interest/100.0)^intervalls_per_week - 1.0)
end

function last_updated(df)
    utc_time = unix2datetime(last(df.TIME))
    local_time = ZonedDateTime(utc_time, TimeZone("Europe/Amsterdam"); from_utc=true)
    last_updated = replace(string(local_time), "+01:00" => "")
    return replace(last_updated, "T" => " ")
end