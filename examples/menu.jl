# Interactive terminal menu for choosing and running one of the project's
# Julia scripts (from src/ and examples/).
#
# Usage (from the Julia REPL, started via bin/run_julia):
#   include("examples/menu.jl")

using REPL.TerminalMenus

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const SCRIPT_DIRS   = ["src", "examples"]

function script_description(path::AbstractString)
    for line in eachline(path)
        stripped = strip(line)
        isempty(stripped) && continue
        m = match(r"^#+\s*(.*)$", stripped)
        return m === nothing ? "" : m.captures[1]
    end
    return ""
end

function included_files(path::AbstractString)
    included = String[]
    for line in eachline(path)
        for m in eachmatch(r"include\(\s*\"([^\"]+)\"\s*\)", line)
            push!(included, normpath(joinpath(dirname(path), m.captures[1])))
        end
    end
    return included
end

# Files that are include()d by another script are helpers, not entry points.
function find_scripts()
    candidates = String[]
    for dir in SCRIPT_DIRS
        full_dir = joinpath(PROJECT_ROOT, dir)
        isdir(full_dir) || continue
        for file in sort(readdir(full_dir))
            endswith(file, ".jl") || continue
            rel = joinpath(dir, file)
            rel == joinpath("examples", "menu.jl") && continue
            push!(candidates, rel)
        end
    end
    helpers = Set{String}()
    for rel in candidates
        union!(helpers, included_files(joinpath(PROJECT_ROOT, rel)))
    end
    return filter(rel -> !(normpath(joinpath(PROJECT_ROOT, rel)) in helpers), candidates)
end

function menu_label(rel_path::AbstractString)
    desc = script_description(joinpath(PROJECT_ROOT, rel_path))
    isempty(desc) ? rel_path : rpad(rel_path, 28) * "- " * desc
end

function run_menu()
    scripts = find_scripts()
    if isempty(scripts)
        println("No Julia scripts found in $(join(SCRIPT_DIRS, ", "))")
        return nothing
    end
    labels = menu_label.(scripts)
    menu = RadioMenu(labels, pagesize=length(labels))
    println("Select a script to run (press q or ctrl-c to cancel):\n")
    choice = request(menu)
    if choice == -1
        println("Cancelled.")
        return nothing
    end
    path = joinpath(PROJECT_ROOT, scripts[choice])
    println("\nRunning $(scripts[choice]) ...\n")
    include(path)
end

run_menu()
