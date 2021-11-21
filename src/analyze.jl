using CSV, DataFrames, Plotly, Dates, TimeZones, Impute

logfiles=["log_1637352719.csv","log_1637489560.csv"]

# fetch the latest log file from the server
function fetch_log()
    mycommand = `./fetch_log.sh`
    run(mycommand)
end

function seconds2human(delta)
    hours = div(delta, 3600)
    reminder = mod(delta, 3600)
    minutes = div(reminder, 60)
    seconds = mod(reminder, 60) 
    return Dates.Hour(hours) + Dates.Minute(minutes) + Dates.Second(seconds)
end

function fill_missing(df)
    t0 = first(df.TIME)
    t_end = last(df.TIME)
    t=t0
    while t <= t_end
        println(t)
        t+=60
    end 
end

function read_log()
    df = nothing
    t_end = 0
    for logfile in logfiles
        df_new = CSV.read("data/" * logfile, DataFrame)
        if isnothing(df)
            df=df_new
            t_end = last(df.TIME)
        else
            t_start = first(df_new.TIME)
            if (t_start - t_end) > 60
               n = div(t_start - t_end + 30, 60)
               v = fill(missing, size(df)[2]-1)
               println("Missing: ", n, " minutes") 
               allowmissing!(df)
               for i in 1:n
                   v1 = vcat([i*60+t_end], v)
                   push!(df, v1)
               end
            end
            df = outerjoin(df, df_new, matchmissing=:equal, on = intersect(names(df),  names(df_new)))
        end
    end
    df = Impute.interp(df)
    disallowmissing!(df)

    new_names=Symbol[]
    i = 1
    for header in names(df)
        push!(new_names, Symbol(replace(header, "-" => "_")))
    end
    rename!(df, new_names)
    data_length = last(df.TIME) - first(df.TIME)
    utc_time = unix2datetime(last(df.TIME))
    local_time = ZonedDateTime(utc_time, TimeZone("Europe/Amsterdam"); from_utc=true) 
    println("Duration:   ", seconds2human(data_length))
    println("Last entry: ", local_time, "\n")
    return df
end

function change_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function plot_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    plot(window, label=name)
end

function plot_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    plot(window, label=name)
end

function change_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function overview(df)
    CHANGES_1h = Float64[]
    CHANGES_24h = Float64[]
    for name in names(df)
        push!(CHANGES_1h,  change_1h(df, Symbol(name)))
        push!(CHANGES_24h, change_24h(df, Symbol(name)))
    end
    res = DataFrame(NAME = names(df), CHANGE_1h = CHANGES_1h, CHANGE_24h = CHANGES_24h)
    delete!(res, 1) # delete time entry
    res_hour = sort!(res, [:CHANGE_1h, :CHANGE_24h], rev=true)
    by_hour = first(res_hour, 5)
    res_day = sort!(res, [:CHANGE_24h, :CHANGE_1h], rev=true)
    by_day  = first(res_day, 5)
    return by_hour, by_day
end

df = read_log()
by_hour, by_day = overview(df)
println(by_hour)
println(by_day)
# p1 = plot(df.BTC_EUR, label="BTC_EUR")
