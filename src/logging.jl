# fetch the latest log file from the server
function fetch_log()
    mycommand = `./fetch_log.sh`
    run(mycommand)
end

function logfiles()
    files=readdir("data")
    filter!(files -> occursin(r"log_", files), files)
    non_empty_files = String[]
    for file in files
        if stat("data/" * file).size > 2000
            push!(non_empty_files, file)
        end
    end
    non_empty_files
end

function read_log(logfiles)
    global T0
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
            t_end = last(df.TIME)
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
    T0 = first(df.TIME)
    return df
end