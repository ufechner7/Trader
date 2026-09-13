using BenchmarkTools, Test, DataFrames, CSV, Dates, TimeZones, Impute, Parameters, JLD2

println("Loading code...")
include("../src/utils.jl")
include("../src/logging.jl")
include("../src/basic.jl")
include("../src/tests.jl")

if ! @isdefined st
    include("../src/analyze.jl")
    println("Loading data...")
    st = load_object("status.jld2")
end

function calc_cash1(tdb::DataFrame)
    cash::Float64 = 0.0
    for row in eachrow(tdb)
        market = row.MARKET
        if market=="DEPOSIT"
            cash += row.SAVE_EUR - row.WITHDRAW_EUR
        elseif market != ""
            cash -= (row.BUY_EUR - row.SELL_EUR)
        end
    end    
    cash
end

function calc_total1(df, tdb)
    total::Float64 = last(tdb.CASH)
    for row in eachrow(tdb)
        market = row.MARKET
        if market!="DEPOSIT" && market != ""
            rate = last(df[!, market])
            total+=(row.BUY_COINS - row.SELL_COINS) * rate
        end
    end
    return total
end

# buy(st, view, rp_table, market, amount; force=false, reason="")

@testset "untils.jl" begin
    @test calc_cash(st.tdb) == calc_cash1(st.tdb)
    @test calc_total(st.df, st.tdb) ≈ calc_total1(st.df, st.tdb)
end

if false
    @btime calc_cash($st.tdb)  #  1.7 μs
    @btime calc_cash1($st.tdb) # 37.6 μs

    @btime calc_total($st.df, $st.tdb)  # 11 μs
    @btime calc_total1($st.df, $st.tdb) # 44 μs
end
nothing
