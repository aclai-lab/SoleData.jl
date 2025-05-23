"""
espresso_minimize(
    syntaxtree::SoleLogics.Formula,
    silent::Bool = true,
    Dflag = "exact",
    Sflag = nothing,
    eflag = nothing,
    args...;
    espressobinary = nothing,
    otherflags = [],
    use_scalar_range_conditions = false,
    kwargs...
)
"""
function espresso_minimize(
    syntaxtree::SoleLogics.Formula,
    silent::Bool = true,
    Dflag = "exact",
    Sflag = nothing,
    eflag = nothing,
    args...;
    espressobinary = nothing,
    otherflags = [],
    use_scalar_range_conditions = false,
    kwargs...
)
    # Determine the path of the espresso binary relative to the location of this file 
    # Consider downloading espresso from https://jackhack96.github.io/logic-synthesis/espresso.html.
    println("============================================")
    if isnothing(espressobinary)
        println("Looking for espresso at $espressobinary")
        espressobinary = joinpath(@__DIR__, "espresso")
        if !isfile(espressobinary)
            error("The 'espresso' binary was not found in the module directory. Please provide espresso path via the espressobinary argument")
        end
    end

    dc_set = false
    pla_string, pla_args, pla_kwargs = PLA._formula_to_pla(syntaxtree, dc_set, silent, args...; use_scalar_range_conditions, kwargs...)

    silent || println()
    silent || println(pla_string)
    silent || println()

    # print(join(pla_content, "\n\n"))
    out = Pipe()
    err = Pipe()

    function escape_for_shell(input::AbstractString)
        # Replace single quotes with properly escaped shell-safe single quotes
        return "$(replace(input, "'" => "\\'"))"
    end

    # echo_cmd = `echo $(escape_for_shell(pla_string))`
    echo_cmd = `echo $(pla_string)`
    # run(echo_cmd)
    args = String[]
    isnothing(Dflag) || push!(args, "-D$(Dflag)")
    isnothing(Sflag) || push!(args, "-S$(Sflag)")
    isnothing(eflag) || push!(args, "-e$(eflag)")
    append!(otherflags, args)
    espresso_cmd = `$espressobinary $args`
    silent || @show espresso_cmd
    cmd = pipeline(pipeline(echo_cmd, espresso_cmd), stdout=out, stderr=err)
    # cmd = pipeline(pipeline(`echo $(escape_for_shell(pla_string))`), stdout=out, stderr=err)
    try
        run(cmd)
        close(out.in)
        close(err.in)
        errstr = String(read(err))
        !isempty(errstr) && (@warn String(read(err)))
    catch
        close(out.in)
        close(err.in)
        errstr = String(read(err))
        !isempty(errstr) && (throw(errstr))
    end

    minimized_pla = String(read(out))
    silent || println(minimized_pla)
    conditionstype = use_scalar_range_conditions ? SoleData.RangeScalarCondition : SoleData.ScalarCondition
    return PLA._pla_to_formula(minimized_pla, silent, pla_args...; conditionstype, pla_kwargs...)
end
