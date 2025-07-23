using Downloads     #only for paper
using Tar                  #


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


#= no auto-setuup version
"""
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

        silent || println("Cleaned minimized PLA:\n$minimized_pla\n")

        conditionstype = use_scalar_range_conditions ? SoleData.RangeScalarCondition : SoleData.ScalarCondition

        # Converti PLA minimizzato in formula
        try
            form = PLA._pla_to_formula(minimized_pla, silent, pla_args...; conditionstype, pla_kwargs...)
            silent || println("formula returned: ",form)
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
=#

"""
    ensure_abc_binary(; force_rebuild = false)

Download, compile, and setup the ABC binary for Boolean function minimization.
Returns the path to the compiled ABC binary.

# Arguments
- `force_rebuild`: If true, forces recompilation even if binary already exists

# Returns
- Path to the ABC binary executable
"""
function ensure_abc_binary(; force_rebuild = false)
    # Path to ABC binary directly in src/ directory
    abc_binary = joinpath(@__DIR__, "abc")
    
    # Return existing binary if found and not forcing rebuild
    if isfile(abc_binary) && !force_rebuild
        @info "ABC binary already exists at: $abc_binary (skipping download/compilation)"
        return abc_binary
    end
    
    @info "Setting up ABC binary..."
    
    # Create unique temporary directory to avoid conflicts
    abc_temp_dir = mktempdir(prefix="abc_build_")
    
    # ABC repository URL (compressed tarball)
    abc_url = "https://github.com/berkeley-abc/abc/archive/refs/heads/master.tar.gz"
    
    try
        # Download the source code
        @info "Downloading ABC source code..."
        tarfile = joinpath(abc_temp_dir, "abc-master.tar.gz")
        Downloads.download(abc_url, tarfile)
        
        # Create subdirectory for extraction to avoid conflicts
        extract_dir = joinpath(abc_temp_dir, "extract")
        mkdir(extract_dir)
        
        # Extract the compressed tarball using system tar command
        # This handles .tar.gz decompression automatically
        @info "Extracting ABC source code..."
        if success(`which tar`)
            # Use system tar command (handles gzip compression)
            run(`tar -xzf $tarfile -C $extract_dir`)
        else
            error("System tar command not found. Please install tar utilities.")
        end

        # Path to extracted source code
        abc_source_dir = joinpath(extract_dir, "abc-master")
        
        if !isdir(abc_source_dir)
            error("Failed to extract ABC source code - directory not found")
        end
        
        # Compile ABC
        @info "Compiling ABC... This may take a few minutes."
        
        # Change to source directory for compilation
        old_dir = pwd()
        cd(abc_source_dir)
        
        try
            # Verify make is available
            if !success(`which make`)
                error("make command not found. Please install build tools (make, gcc, etc.)")
            end
            
            # Compile with make
            run(`make`)
            
            # Copy compiled binary to final location
            compiled_binary = joinpath(abc_source_dir, "abc")
            if isfile(compiled_binary)
                cp(compiled_binary, abc_binary; force=true)
                # Make executable
                chmod(abc_binary, 0o755)
                @info "ABC compiled successfully at: $abc_binary"
            else
                error("ABC compilation completed but binary not found")
            end
            
        finally
            # Always restore original directory
            cd(old_dir)
        end
        
        return abc_binary
        
    catch e
        @error "Failed to download/compile ABC: $e. Consider downloading ABC manually from https://github.com/berkeley-abc/abc"
        rethrow(e)
    finally
        # Always cleanup temporary directory
        try
            rm(abc_temp_dir; recursive=true, force=true)
        catch cleanup_error
            @warn "Failed to cleanup temporary directory: $cleanup_error"
        end
    end
end

"""
    abc_minimize(syntaxtree, silent=true; kwargs...)

Minimize a Boolean formula using the ABC tool with automatic setup.

# Arguments
- `syntaxtree`: SoleLogics.Formula to minimize
- `silent`: If true, suppress output messages
- `fast`: If true, use faster but less aggressive minimization
- `abcbinary`: Path to ABC binary (auto-detected if nothing)
- `force_rebuild_abc`: Force recompilation of ABC binary
- `use_scalar_range_conditions`: Use range conditions for scalars
- `otherflags`: Additional flags for ABC (currently unused)

# Returns
- Minimized formula or original formula if minimization fails
"""
function abc_minimize(
    syntaxtree::SoleLogics.Formula,
    silent::Bool = true,
    args...;
    fast = true,
    abcbinary = nothing,
    otherflags = [],
    use_scalar_range_conditions = false,
    force_rebuild_abc = false,
    kwargs...
)
    println("Using abc_minimize function with auto-setup")
    # Auto-setup ABC binary if not specified
    if isnothing(abcbinary)
        try
            abcbinary = ensure_abc_binary(; force_rebuild = force_rebuild_abc)
        catch e
            error("Failed to setup ABC binary: $e")
        end
    end
    
    # Verify binary exists and is executable
    if !isfile(abcbinary)
        error("ABC binary not found at $abcbinary")
    end
    
    # Test that ABC binary works
    try
        run(`$abcbinary -h`; wait=false)
    catch e
        @warn "ABC binary may not be working properly: $e"
    end

    # Internal utility to remove whitespace from strings
    removewhitespaces(s::AbstractString) = replace(s, r"\s+" => "")

    # Convert formula to PLA string format
    dc_set = false
    pla_string, pla_args, pla_kwargs = PLA._formula_to_pla(
        syntaxtree, dc_set, silent; 
        use_scalar_range_conditions=use_scalar_range_conditions
    )

    silent || println("Input PLA:\n$pla_string\n")

    """
    Validate and fix PLA format issues, particularly input/output count mismatches.
    """
    function validate_and_fix_pla(pla_content::String)
        lines = split(pla_content, '\n')
        # Filter empty lines and fix Unicode symbols
        filtered_lines = filter(line -> !isempty(strip(line)), lines)
        filtered_lines = map(line -> replace(line, "≥" => ">="), filtered_lines)
        
        # Find header lines
        i_line_idx = findfirst(line -> startswith(line, ".i "), filtered_lines)
        o_line_idx = findfirst(line -> startswith(line, ".o "), filtered_lines)
        ilb_line_idx = findfirst(line -> startswith(line, ".ilb "), filtered_lines)
        olb_line_idx = findfirst(line -> startswith(line, ".olb "), filtered_lines)
        
        if isnothing(i_line_idx) || isnothing(o_line_idx)
            error("PLA format invalid: missing .i or .o lines")
        end
        
        # Extract declared input/output counts
        i_count = parse(Int, split(filtered_lines[i_line_idx])[2])
        o_count = parse(Int, split(filtered_lines[o_line_idx])[2])
        
        # Count actual variables from labels or product terms
        actual_inputs = 0
        if !isnothing(ilb_line_idx)
            ilb_parts = split(filtered_lines[ilb_line_idx])[2:end]
            actual_inputs = length(ilb_parts)
        else
            # Count from product terms if no labels
            product_lines = filter(line -> occursin(r"^[01\-]+ ", line), filtered_lines)
            if !isempty(product_lines)
                first_product = split(product_lines[1])[1]
                actual_inputs = length(first_product)
            end
        end
        
        # Fix input count mismatch
        if actual_inputs > 0 && actual_inputs != i_count
            silent || println("Fixing input count mismatch: declared=$i_count, actual=$actual_inputs")
            filtered_lines[i_line_idx] = ".i $actual_inputs"
        end
        
        return join(filtered_lines, '\n')
    end

    # Validate and correct PLA format
    corrected_pla = validate_and_fix_pla(String(pla_string))
    silent || println("Corrected PLA:\n$corrected_pla")
    
    # Create temporary files for input/output
    inputfile = tempname() * ".pla"
    outputfile = tempname() * ".pla"

    try
        # Write corrected PLA to input file
        open(inputfile, "w") do f
            write(f, corrected_pla)
        end

        silent || println("PLA written to: $inputfile")

        # Define ABC command sequence
        if fast
            # Fast minimization - basic optimization
            abc_commands = [
                "read $inputfile",
                "strash",           # Convert to AIG
                "collapse",         # Collapse to SOP
                "write $outputfile"             
            ]
        else
            # Thorough minimization - multiple optimization passes
            abc_commands = [
                "read $inputfile",
                "sop",              # Convert to sum-of-products
                "strash",           # Convert to AIG
                "dc2",              # Don't-care minimization
                "collapse",         # Collapse logic
                "strash",           # Convert to AIG again
                "dc2",              # Another DC pass
                "collapse",         # Final collapse
                "sop",              # Back to SOP
                "write $outputfile"
            ]
        end
        
        # Build ABC command string
        abc_cmd_str = join(abc_commands, "; ")
        abc_cmd = `$abcbinary -c $abc_cmd_str`
        
        silent || println("Running ABC command: $abc_cmd")
        
        # Execute ABC with error handling
        result = try
            run(abc_cmd)
            true
        catch e
            silent || println("ABC command failed: $e")
            false
        end
        
        # Check if ABC succeeded and produced output
        if !result || !isfile(outputfile)
            silent || println("ABC failed or output file not created, returning original formula")
            return syntaxtree
        end

        # Read minimized PLA output
        minimized_pla_raw = read(outputfile, String)
        minimized_pla_raw = replace(minimized_pla_raw, ">=" => "≥")

        silent || println("Raw ABC output:\n$minimized_pla_raw")

        # Check for empty output
        if isempty(strip(minimized_pla_raw))
            silent || println("Empty ABC output, returning original formula")
            return syntaxtree
        end

        """
        Clean ABC output by keeping only relevant PLA lines.
        """
        function clean_abc_output(raw_pla::String)
            lines = split(raw_pla, '\n')
            # Keep only PLA format lines (headers and product terms)
            pla_lines = filter(line -> !isempty(strip(line)) && 
                              (startswith(line, '.') || occursin(r"^[01\-]+ ", line)), lines)
            return join(pla_lines, '\n')
        end

        minimized_pla = clean_abc_output(minimized_pla_raw)
        silent || println("Cleaned minimized PLA:\n$minimized_pla\n")

        # Determine condition type for conversion
        conditionstype = use_scalar_range_conditions ? SoleData.RangeScalarCondition : SoleData.ScalarCondition

        # Convert minimized PLA back to formula
        try
            form = PLA._pla_to_formula(
                minimized_pla, silent, pla_args...; 
                conditionstype, pla_kwargs...
            )
            silent || println("Minimized formula: $form")
            return form
        catch e
            silent || println("Failed to convert minimized PLA back to formula: $e")
            silent || println("Returning original formula")
            return syntaxtree
        end

    finally
        # Always cleanup temporary files
        rm(inputfile; force=true)
        rm(outputfile; force=true)
    end
end

"""
    cleanup_temp_abc_dirs()

Clean up any leftover temporary ABC build directories.
Useful for maintenance and debugging.
"""
function cleanup_temp_abc_dirs()
    temp_pattern = r"abc_build_\w+"
    temp_base = tempdir()
    
    for item in readdir(temp_base)
        if occursin(temp_pattern, item)
            full_path = joinpath(temp_base, item)
            if isdir(full_path)
                try
                    rm(full_path; recursive=true, force=true)
                    @info "Cleaned up leftover temp directory: $full_path"
                catch e
                    @warn "Could not clean $full_path: $e"
                end
            end
        end
    end
end

"""
    clean_abc_installation()

Remove the ABC binary installation from the source directory.
Useful for forcing a fresh installation.
"""
function clean_abc_installation()
    abc_binary = joinpath(@__DIR__, "abc")
    if isfile(abc_binary)
        rm(abc_binary; force=true)
        @info "ABC binary removed from: $abc_binary"
    else
        @info "No ABC binary found to remove"
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
        
        silent || println("=== Original PLA ===")
        silent || println(pla_string)
        silent || println("=== BOOM PLA Content (Corrected) ===")
        silent || println(minimized_output)
        silent || println("=== Debug Info ===")
        silent || println("pla_args: ", pla_args)
        silent || println("pla_kwargs: ", pla_kwargs)
        silent || println("original_ilb: ", original_ilb)
        silent || println("original_ob: ", original_ob)
        silent || println("==========================")
        
        # Pass original arguments to maintain variable labels
        result = PLA._pla_to_formula(minimized_output, silent, pla_args...; pla_kwargs..., featvaltype=Float64)
        silent || println("=== Resulting Formula ===")
        silent || println(result)
        silent || println("==========================")
        return result
        
    finally
        isfile(infile) && rm(infile; force=true)
        isfile(outfile) && rm(outfile; force=true)
    end
end
