@info "Loading packages ..."
using TimeZones, Dates, FluxArchitectures
using PackageCompiler

TimeZones.build()

@info "Creating sysimage ..."

PackageCompiler.create_sysimage(
    [:TimeZones, :FluxArchitectures];
    sysimage_path="MakieSys_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)