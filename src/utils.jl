function seconds2human(delta)
    hours = div(delta, 3600)
    reminder = mod(delta, 3600)
    minutes = div(reminder, 60)
    seconds = mod(reminder, 60) 
    return Dates.Hour(hours) + Dates.Minute(minutes) + Dates.Second(seconds)
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