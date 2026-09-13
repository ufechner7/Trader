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

function load_state()
    println("Loading data...")
    st = load_object("status.jld2")
    new_logfiles=String[]
    for logfile in logfiles()
        if ! (logfile in st.logfiles)
            push!(new_logfiles, logfile)
        end
    end
    st.df = read_log(new_logfiles; df=st.df)
    st.t0 = first(st.df.TIME)
    st.logfiles = logfiles()
    if length(new_logfiles) > 0
        st.tdb = nothing
        st.rdb = nothing
        st.rp_table = nothing
        st.δ_rating = Dict{String, Float64}()
    end
    return st
end

function save_state(st)
    jldsave("status.jld2"; st)
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