@info "Loading packages ..."
using FluxArchitectures, Plots, CSV, DataFrames, PyPlot, TimeZones
using PackageCompiler

@info "Creating sysimage ..."
push!(LOAD_PATH,joinpath(pwd(),"src"))

PackageCompiler.create_sysimage(
    [:FluxArchitectures, :Plots, :CSV, :DataFrames, :PyPlot, :TimeZones];
    sysimage_path="MakieSys_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)