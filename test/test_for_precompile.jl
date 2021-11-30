using FluxArchitectures, Plots

@info "Loading data"
poollength = 10
horizon = 15
datalength = 1000
input, target = get_data(:exchange_rate, poollength, datalength, horizon)

@info "Creating model and loss"
inputsize = size(input, 1)
convlayersize = 2
recurlayersize = 3
skiplength = 240
model = LSTnet(inputsize, convlayersize, recurlayersize, poollength, skiplength, init=Flux.zeros32, initW=Flux.zeros32)

function loss(x, y)
    Flux.reset!(model)
    return Flux.mse(model(x), y')
end

cb = function ()
    Flux.reset!(model)
    pred = model(input)' |> cpu
    Flux.reset!(model)
    p1 = plot(pred, label="Predict")
    p1 = plot!(cpu(target), label="Data", title="Loss $(loss(input, target))")
    display(plot(p1))
end

@info "Start loss" loss = loss(input, target)
@info "Starting training"
Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 2), ADAM(0.01), cb=cb)
@info "Final loss" loss = loss(input, target)

println("-------------------------------------")
using CSV, DataFrames, Dates, TimeZones, Impute

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

function read_log(logfiles; df = nothing)   
    t_end = 0
    if ! isnothing(df)
        t_end = last(df.TIME)
    end
    for logfile in logfiles
        df_new = CSV.read("data/" * logfile, DataFrame; ntasks=1)
        new_names=Symbol[]
        for header in names(df_new)
            push!(new_names, Symbol(replace(header, "-" => "_")))
        end
        rename!(df_new, new_names)
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
            t_end = last(df.TIME)
        end
    end

    df = Impute.interp(df)
    disallowmissing!(df)


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

df = read_log(["log_1637352719.csv"])
by_hour, by_day = overview(df)
println(by_hour)
println(by_day)

@info "Precompile script has completed execution."