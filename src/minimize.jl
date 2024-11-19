
function espresso_minimize(syntaxtree::SoleLogics.Formula, silent::Bool = true, Dflag = "exact", Sflag = nothing, eflag = nothing, args...; otherflags = [], kwargs...)
    dc_set = false
    pla_string, others... = PLA._formula_to_pla(syntaxtree, dc_set, silent, args...; kwargs...)

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
    cmd = pipeline(pipeline(echo_cmd, `./espresso $args`), stdout=out, stderr=err)
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
    return PLA._pla_to_formula(minimized_pla, others...)
end
