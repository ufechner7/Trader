# Basic statistics

const NoDataFrame = Union{Nothing, DataFrame}

@enum Mode INIT=1 RATING=2 MIXED=3 STOPPED=4

@with_kw mutable struct State @deftype Int64
   t0                =  0                  # start time [s]
   index             =  1                  # last index of the input data frame
   wait              =  60                 # number of seconds to wait before trading
   mode::Mode        = INIT
   df::NoDataFrame              = nothing  # input data frame
   tdb::NoDataFrame             = nothing  # trading data frame
   rdb::NoDataFrame             = nothing  # rating data frame
   rel_price_table::NoDataFrame = nothing  # prices relative to buying time
   markets::Vector{String}      = []       # currently owned coins
end

function State(df)
    st=State()
    st.df = df
    st.t0 = first(df.TIME)
    st
end

function Base.getproperty(st::State, sym::Symbol)
    if sym == :time
        df = getfield(st, :df)
        index = getfield(st, :index)
        df.TIME[index]
    else
        getfield(st, sym)
    end
end

function rise_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function drop_1h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-60+1), 1):end]
    max1     = maximum(window)
    current = last(col)
    drop = (current/max1 - 1.0) * 100.0
end

function drop_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    max1     = maximum(window)
    current = last(col)
    drop = (current/max1 - 1.0) * 100.0
end

function rise_24h(df, name)
    col     = df[!, name]
    window = col[max((length(col)-24*60+1), 1):end]
    min     = minimum(window)
    current = last(col)
    change = (current/min - 1.0) * 100.0
end

function overview(df)
    CHANGES_1h = Float64[]
    CHANGES_24h = Float64[]
    DROP_1h = Float64[]
    DROP_24h = Float64[]
    for name in names(df)
        push!(CHANGES_1h,  rise_1h(df, Symbol(name)))
        push!(CHANGES_24h, rise_24h(df, Symbol(name)))
        push!(DROP_1h, drop_1h(df, Symbol(name)))
        push!(DROP_24h, drop_24h(df, Symbol(name)))
    end
    res = DataFrame(MARKET = names(df), RISE_1h = CHANGES_1h, DROP_1h = DROP_1h, RISE_24h = CHANGES_24h, DROP_24h = DROP_24h)
    delete!(res, 1) # delete time entry
    res_hour = sort!(res, [:RISE_1h, :RISE_24h], rev=true)
    by_hour = first(res_hour, 8)
    res_day = sort!(res, [:RISE_24h, :RISE_1h], rev=true)
    by_day  = first(res_day, 8)
    return by_hour, by_day
end