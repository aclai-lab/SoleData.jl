"""
by https://jackhack96.github.io/logic-synthesis/espresso.html. 
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

"""
by  https://github.com/berkeley-abc/abc
abc_minimize(
    syntaxtree::SoleLogics.Formula,
    silent::Bool = true,
    args...;
    abcbinary = nothing,
    otherflags = [],
    use_scalar_range_conditions = false,
    kwargs...
)
"""
function abc_minimize(
    syntaxtree::SoleLogics.Formula,
    silent::Bool = true,
    args...;
    fast = true,
    abcbinary = nothing,
    otherflags = [],
    use_scalar_range_conditions = false,
    kwargs...
)
    if isnothing(abcbinary)
        # Determine the path of the abc binary relative to the location of this file 
        # Consider downloading abc from https://github.com/berkeley-abc/abc.
        abcbinary = joinpath(@__DIR__, "abc")
        if !isfile(abcbinary)
            error("abc binary not found at $abcbinary, provide path with abcbinary argument")
        end
    end

    # Funzione interna per rimuovere spazi da stringhe
    removewhitespaces(s::AbstractString) = replace(s, r"\s+" => "")

    # Converte formula in PLA string
    dc_set = false
    pla_string, pla_args, pla_kwargs = PLA._formula_to_pla(syntaxtree, dc_set, silent; use_scalar_range_conditions=use_scalar_range_conditions)

    silent || println("Input PLA:\n$pla_string\n")

    # Validazione e correzione del formato PLA
    function validate_and_fix_pla(pla_content::String)
        lines = split(pla_content, '\n')
        filtered_lines = filter(line -> !isempty(strip(line)), lines)
        filtered_lines = map(line -> replace(line, "≥" => ">="), filtered_lines)
        
        # Trova le righe di intestazione
        i_line_idx = findfirst(line -> startswith(line, ".i "), filtered_lines)
        o_line_idx = findfirst(line -> startswith(line, ".o "), filtered_lines)
        ilb_line_idx = findfirst(line -> startswith(line, ".ilb "), filtered_lines)
        olb_line_idx = findfirst(line -> startswith(line, ".olb "), filtered_lines)
        
        if isnothing(i_line_idx) || isnothing(o_line_idx)
            error("PLA format invalid: missing .i or .o lines")
        end
        
        # Estrai il numero di input/output
        i_count = parse(Int, split(filtered_lines[i_line_idx])[2])
        o_count = parse(Int, split(filtered_lines[o_line_idx])[2])
        
        # Conta le variabili effettive dai label se esistono
        actual_inputs = 0
        if !isnothing(ilb_line_idx)
            ilb_parts = split(filtered_lines[ilb_line_idx])[2:end]
            actual_inputs = length(ilb_parts)
        else
            # Se non ci sono label, conta dalle righe di prodotto
            product_lines = filter(line -> occursin(r"^[01\-]+ ", line), filtered_lines)
            if !isempty(product_lines)
                first_product = split(product_lines[1])[1]
                actual_inputs = length(first_product)
            end
        end
        
        # Correggi il mismatch se necessario
        if actual_inputs > 0 && actual_inputs != i_count
            silent || println("Fixing input count mismatch: declared=$i_count, actual=$actual_inputs")
            filtered_lines[i_line_idx] = ".i $actual_inputs"
        end
        

        return join(filtered_lines, '\n')
    end

    # Valida e correggi il PLA
    corrected_pla = validate_and_fix_pla(String(pla_string))
    silent || println("corrected pls: \n",corrected_pla)
    # File temporanei input e output
    inputfile = tempname() * ".pla"
    outputfile = tempname() * ".pla"

    try
        # Scrivi PLA corretto su file input
        open(inputfile, "w") do f
            write(f, corrected_pla)
        end

        silent || println("Corrected PLA written to: $inputfile")

        # Comando abc
        if fast
        abc_commands = [
            "read $inputfile",
            "strash", 
            "dc2",
            "collapse",
            "write $outputfile"             

            #"read $inputfile",
            #"strash",            # diretto in AIG
            #"refactor -z",      # flag -z per velocità
            #"rewrite -z", 
            #"balance",
            #"collapse",
            #"write $outputfile"  # mantieni AIG ottimizzato
        ]
        else
        abc_commands = [
            "read $inputfile",
            "sop",
            "strash",
            "dc2",
            "collapse",
            "strash",
            "dc2", 
            "collapse",
            "sop",              
            "write $outputfile"
        ]
        end
        
        abc_cmd_str = join(abc_commands, "; ")
        abc_cmd = `$abcbinary -c $abc_cmd_str`
        
        silent || println("Running ABC command: $abc_cmd")
        
        # Esegui comando con cattura output/errori
        result = try
            run(abc_cmd)
            true
        catch e
            silent || println("ABC command failed: $e")
            false
        end
        
        if !result || !isfile(outputfile)
            silent || println("ABC failed or output file not created, returning original formula")
            return syntaxtree
        end

        # Leggi output minimizzato
        minimized_pla_raw = read(outputfile, String)
        minimized_pla_raw = replace(minimized_pla_raw, ">=" => "≥")

        silent || println("good minimze the king: ",minimized_pla_raw)

        if isempty(strip(minimized_pla_raw))
            silent || println("Empty ABC output, returning original formula")
            return syntaxtree
        end

        silent || println("Raw minimized PLA output:\n$minimized_pla_raw\n")

        # Pulizia output
        function clean_abc_output(raw_pla::String)
            lines = split(raw_pla, '\n')
            pla_lines = filter(line -> !isempty(strip(line)) && 
                              (startswith(line, '.') || occursin(r"^[01\-]+ ", line)), lines)
            return join(pla_lines, '\n')
        end

        minimized_pla = clean_abc_output(minimized_pla_raw)

        println("Cleaned minimized PLA:\n$minimized_pla\n")

        conditionstype = use_scalar_range_conditions ? SoleData.RangeScalarCondition : SoleData.ScalarCondition

        # Converti PLA minimizzato in formula
        try
            form = PLA._pla_to_formula(minimized_pla, silent, pla_args...; conditionstype, pla_kwargs...)
            println("formula returned: ",form)
            return form
        catch e
            silent || println("Failed to convert minimized PLA back to formula: $e")
            silent || println("Returning original formula")
            return syntaxtree
        end

    finally
        # Elimina file temporanei
        rm(inputfile; force=true)
        rm(outputfile; force=true)
    end
end

#=
    function espressoTexas_minimize(
        syntaxtree::SoleLogics.Formula,
        silent::Bool = true,
        args...;
        espressobinary = nothing,
        otherflags = [],
        use_scalar_range_conditions = false,
        kwargs...
    )
        if isnothing(espressobinary)
            # Determine the path of the abc binary relative to the location of this file 
            # Consider downloading abc from https://github.com/berkeley-abc/abc.
            espressobinary = joinpath(@__DIR__, "espresso.linux")
            if !isfile(espressobinary)
                error("abc binary not found at $espressobinary, provide path with espressobinary argument")
            end
        end

        # Funzione interna per rimuovere spazi da stringhe
        removewhitespaces(s::AbstractString) = replace(s, r"\s+" => "")

        # Converte formula in PLA string
        dc_set = false
        pla_string, pla_args, pla_kwargs = PLA._formula_to_pla(syntaxtree, dc_set, silent; use_scalar_range_conditions=use_scalar_range_conditions)

        silent || println("Input PLA:\n$pla_string\n")

        # Validazione e correzione del formato PLA
        function validate_and_fix_pla(pla_content::String)
            lines = split(pla_content, '\n')
            filtered_lines = filter(line -> !isempty(strip(line)), lines)
            
            # Trova le righe di intestazione
            i_line_idx = findfirst(line -> startswith(line, ".i "), filtered_lines)
            o_line_idx = findfirst(line -> startswith(line, ".o "), filtered_lines)
            ilb_line_idx = findfirst(line -> startswith(line, ".ilb "), filtered_lines)
            olb_line_idx = findfirst(line -> startswith(line, ".olb "), filtered_lines)
            
            if isnothing(i_line_idx) || isnothing(o_line_idx)
                error("PLA format invalid: missing .i or .o lines")
            end
            
            # Estrai il numero di input/output
            i_count = parse(Int, split(filtered_lines[i_line_idx])[2])
            o_count = parse(Int, split(filtered_lines[o_line_idx])[2])
            
            # Conta le variabili effettive dai label se esistono
            actual_inputs = 0
            if !isnothing(ilb_line_idx)
                ilb_parts = split(filtered_lines[ilb_line_idx])[2:end]
                actual_inputs = length(ilb_parts)
            else
                # Se non ci sono label, conta dalle righe di prodotto
                product_lines = filter(line -> occursin(r"^[01\-]+ ", line), filtered_lines)
                if !isempty(product_lines)
                    first_product = split(product_lines[1])[1]
                    actual_inputs = length(first_product)
                end
            end
            
            # Correggi il mismatch se necessario
            if actual_inputs > 0 && actual_inputs != i_count
                silent || println("Fixing input count mismatch: declared=$i_count, actual=$actual_inputs")
                filtered_lines[i_line_idx] = ".i $actual_inputs"
            end
            

            return join(filtered_lines, '\n')
        end

        # Valida e correggi il PLA
        corrected_pla = validate_and_fix_pla(String(pla_string))
        silent || println("corrected pls: \n",corrected_pla)
        # File temporanei input e output
        inputfile = tempname() * ".pla"
        outputfile = tempname() * ".pla"

        try
            # Scrivi PLA corretto su file input
            open(inputfile, "w") do f
                write(f, corrected_pla)
            end

            silent || println("Corrected PLA written to: $inputfile")
            
            espresso_cmd = `$espressobinary  $inputfile`
            
            silent || println("Running ESPRESSO command: $espresso_cmd")
            
            # Esegui comando con cattura output/errori
            result = try
                run(espresso_cmd)
                true
            catch e
                silent || println("ESPRESSO command failed: $e")
                false
            end
            
            if !result || !isfile(outputfile)
                silent || println("ESPRESSO failed or output file not created, returning original formula")
                return syntaxtree
            end

            # Leggi output minimizzato
            minimized_pla_raw = read(outputfile, String)
            minimized_pla_raw = replace(minimized_pla_raw, ">=" => "≥")

            silent ||  println("good minimized the king: ",minimized_pla_raw)

            if isempty(strip(minimized_pla_raw))
                silent || println("Empty ESPRESSO output, returning original formula")
                return syntaxtree
            end

            silent || println("Raw minimized PLA output:\n$minimized_pla_raw\n")

            # Pulizia output
            function clean_ESPRESSO_output(raw_pla::String)
                lines = split(raw_pla, '\n')
                pla_lines = filter(line -> !isempty(strip(line)) && 
                                (startswith(line, '.') || occursin(r"^[01\-]+ ", line)), lines)
                return join(pla_lines, '\n')
            end

            minimized_pla = clean_ESPRESSO_output(minimized_pla_raw)

            silent || println("Cleaned minimized PLA:\n$minimized_pla\n")

            conditionstype = use_scalar_range_conditions ? SoleData.RangeScalarCondition : SoleData.ScalarCondition

            # Converti PLA minimizzato in formula
            try
                return PLA._pla_to_formula(minimized_pla, silent, pla_args...; conditionstype, pla_kwargs...)
            catch e
                silent || println("Failed to convert minimized PLA back to formula: $e")
                silent || println("Returning original formula")
                return syntaxtree
            end

        finally
            # Elimina file temporanei
            rm(inputfile; force=true)
            rm(outputfile; force=true)
        end
    end 
=#

function mktemp_pla()
    (f, io) = mktemp()
    close(io)
    newf = f * ".pla"
    cp(f, newf; force=true)
    rm(f; force=true)
    (newf, open(newf, "w"))
end


function boom_minimize(f::LeftmostLinearForm, single::Bool, name::String = "", silent::Bool = true; kwargs...)
    #print(dump(f))
    pla_string, pla_args, pla_kwargs = PLA._formula_to_pla(f, false, silent; necessary_type=true, kwargs...) 

    (infile, infile_io) = mktemp_pla()
    (outfile, outfile_io) = mktemp_pla()
    close(outfile_io)

    try
        write(infile_io, pla_string)
        close(infile_io)

        boom_exe = joinpath(@__DIR__, "boom.exe")
        sh_cmd = `sh -c "wine $boom_exe $infile > $outfile"`
        run(sh_cmd)

        minimized_output = read(outfile, String)
        
        # Remove .type line that causes parser issues
        minimized_output = replace(minimized_output, r"\.type.*\n" => "")
        
        # ===== PLA FORMAT NORMALIZATION =====
        # Convert "000000 1" format to "0000001" for compatibility with _pla_to_formula parser
        lines = split(minimized_output, '\n')
        normalized_lines = String[]
        
        for line in lines
            line = strip(line)
            
            # If line contains binary pattern + space + output, normalize it
            if match(r"^[01-]+\s+[01]$", line) !== nothing
                parts = split(line)
                binary_part = parts[1]
                output_part = parts[2]
                # Combine into space-free format
                normalized_line = binary_part * output_part
                push!(normalized_lines, normalized_line)
            else
                # Keep line as is
                push!(normalized_lines, line)
            end
        end
        
        minimized_output = join(normalized_lines, '\n')
        
        # ===== MAIN CORRECTION =====
        # Extract variable labels from original PLA
        original_lines = split(pla_string, '\n')
        original_ilb = ""
        original_ob = ""
        
        for line in original_lines
            line = strip(line)
            if startswith(line, ".ilb ")
                original_ilb = line
            elseif startswith(line, ".ob ")
                original_ob = line
            end
        end
        
        # Handle special case where BOOM minimizes everything to "always true"
        lines = split(minimized_output, '\n')
        processed_lines = String[]
        
        # Add original labels if missing
        ilb_added = false
        ob_added = false
        
        for line in lines
            line = strip(line)
            
            # Add .ilb after .i if not present
            if startswith(line, ".i ") && !ilb_added && !isempty(original_ilb)
                push!(processed_lines, line)
                push!(processed_lines, original_ilb)
                ilb_added = true
                continue
            end
            
            # Add .ob after .o if not present  
            if startswith(line, ".o ") && !ob_added && !isempty(original_ob)
                push!(processed_lines, line)
                push!(processed_lines, original_ob)
                ob_added = true
                continue
            end
            
            # Handle tautology case (all don't-care followed by output)
            if match(r"^-+\s*(\d+)\s*$", line) !== nothing
                # BOOM minimized everything to "always true" (tautology)
                # Replace with simple rule without don't care
                m = match(r"^-+\s*(\d+)\s*$", line)
                output = m.captures[1]
                
                # Extract number of input variables from original PLA
                i_count = 0
                for orig_line in original_lines
                    if startswith(strip(orig_line), ".i ")
                        i_count = parse(Int, split(strip(orig_line))[2])
                        break
                    end
                end
                
                # Create rule with all 0s (or first valid combination)
                zeros_pattern = repeat("0", i_count)
                push!(processed_lines, "$zeros_pattern$output")
                
            elseif occursin("-", line) && match(r"^[01-]+\s*\d+", line) !== nothing
                # Keep don't care rules for now, but could expand all combinations
                push!(processed_lines, line)
            else
                push!(processed_lines, line)
            end
        end
        
        # Update .p count if necessary
        rule_count = count(x -> match(r"^[01-]+\d+", x) !== nothing, processed_lines)
        if rule_count > 0
            processed_lines = map(processed_lines) do line
                if startswith(line, ".p ")
                    ".p $rule_count"
                else
                    line
                end
            end
        end
        
        minimized_output = join(processed_lines, '\n')
        
        println("=== Original PLA ===")
        println(pla_string)
        println("=== BOOM PLA Content (Corrected) ===")
        println(minimized_output)
        println("=== Debug Info ===")
        println("pla_args: ", pla_args)
        println("pla_kwargs: ", pla_kwargs)
        println("original_ilb: ", original_ilb)
        println("original_ob: ", original_ob)
        println("==========================")
        
        # Pass original arguments to maintain variable labels
        result = PLA._pla_to_formula(minimized_output, silent, pla_args...; pla_kwargs..., featvaltype=Float64)
        println("=== Resulting Formula ===")
        println(result)
        println("==========================")
        return result
        
    finally
        isfile(infile) && rm(infile; force=true)
        isfile(outfile) && rm(outfile; force=true)
    end
end
