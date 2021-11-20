using CSV, DataFrames, Plots

function read_log()
    df = CSV.read("data/log_1637352719.csv", DataFrame)
    new_names=Symbol[]
    i = 1
    for header in names(df)
        push!(new_names, Symbol(replace(header, "-" => "_")))
    end
    rename!(df, new_names)
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
    res = sort!(res, [:CHANGE_1h, :CHANGE_24h], rev=true)
    first(res, 5)
end

df = read_log()
ov = overview(df)
# p1 = plot(df.BTC_EUR, label="BTC_EUR")
