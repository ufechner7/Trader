@info "Loading packages ..."
using FluxArchitectures, Plots, CSV, DataFrames, TimeZones, Dates, TimeZones, Impute, Statistics, GLM, Parameters, JLD2
using PackageCompiler

@info "Creating sysimage ..."
push!(LOAD_PATH,joinpath(pwd(),"src"))

PackageCompiler.create_sysimage(
    [:FluxArchitectures, :Plots, :CSV, :DataFrames, :TimeZones, :Impute, :Statistics, :GLM, :Parameters, :JLD2];
    sysimage_path="MakieSys_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)