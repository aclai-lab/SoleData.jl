# This file is almost deprecated, with an exception for parseARFF function;
# TODO: when .Artifacts module is completed, forward all the calls to this load_arff_dataset
# to the proper loader.

using HTTP
using ZipFile
using DataFrames
using CategoricalArrays
using InteractiveUtils

using DataStructures: OrderedDict

function load_arff_dataset(
    dataset_name,
    split = :all;
    # path = "http://www.timeseriesclassification.com/aeon-toolkit/$(dataset_name).zip"
    path = "https://github.com/PasoStudio73/datasets/raw/refs/heads/main/NATOPS.zip"
)
    @assert split in [:train, :test, :split, :all] "Unexpected value for split parameter: $(split). Allowed: :train, :test, :split, :all."

    # function load_arff_dataset(dataset_name, path = "../datasets/Multivariate_arff/$(dataset_name)")
    (X_train, y_train), (X_test, y_test) = begin
        if(any(startswith.(path, ["https://", "http://"])))
            r = HTTP.get(path);
            z = ZipFile.Reader(IOBuffer(r.body))
            # (
            #     ARFFFiles.load(DataFrame, z.files[[f.name == "$(dataset_name)_TRAIN.arff" for f in z.files]][1]),
            #     ARFFFiles.load(DataFrame, z.files[[f.name == "$(dataset_name)_TEST.arff" for f in z.files]][1]),
            # )
            (
                read(z.files[[f.name == "$(dataset_name)_TRAIN.arff" for f in z.files]][1], String) |> parseARFF,
                read(z.files[[f.name == "$(dataset_name)_TEST.arff" for f in z.files]][1], String) |> parseARFF,
            )
        else
            (
                # ARFFFiles.load(DataFrame, "$(path)/$(dataset_name)_TRAIN.arff"),
                # ARFFFiles.load(DataFrame, "$(path)/$(dataset_name)_TEST.arff"),
                read("$(path)/$(dataset_name)_TEST.arff", String) |> parseARFF,
                read("$(path)/$(dataset_name)_TRAIN.arff", String) |> parseARFF,
            )
        end
    end

    @assert dataset_name == "NATOPS" "This code is only for showcasing. Need to expand code to comprehend more datasets."
    # variable_names = [
    #     "Hand tip left, X coordinate",
    #     "Hand tip left, Y coordinate",
    #     "Hand tip left, Z coordinate",
    #     "Hand tip right, X coordinate",
    #     "Hand tip right, Y coordinate",
    #     "Hand tip right, Z coordinate",
    #     "Elbow left, X coordinate",
    #     "Elbow left, Y coordinate",
    #     "Elbow left, Z coordinate",
    #     "Elbow right, X coordinate",
    #     "Elbow right, Y coordinate",
    #     "Elbow right, Z coordinate",
    #     "Wrist left, X coordinate",
    #     "Wrist left, Y coordinate",
    #     "Wrist left, Z coordinate",
    #     "Wrist right, X coordinate",
    #     "Wrist right, Y coordinate",
    #     "Wrist right, Z coordinate",
    #     "Thumb left, X coordinate",
    #     "Thumb left, Y coordinate",
    #     "Thumb left, Z coordinate",
    #     "Thumb right, X coordinate",
    #     "Thumb right, Y coordinate",
    #     "Thumb right, Z coordinate",
    # ]

    variable_names = [
        "X[Hand tip l]",
        "Y[Hand tip l]",
        "Z[Hand tip l]",
        "X[Hand tip r]",
        "Y[Hand tip r]",
        "Z[Hand tip r]",
        "X[Elbow l]",
        "Y[Elbow l]",
        "Z[Elbow l]",
        "X[Elbow r]",
        "Y[Elbow r]",
        "Z[Elbow r]",
        "X[Wrist l]",
        "Y[Wrist l]",
        "Z[Wrist l]",
        "X[Wrist r]",
        "Y[Wrist r]",
        "Z[Wrist r]",
        "X[Thumb l]",
        "Y[Thumb l]",
        "Z[Thumb l]",
        "X[Thumb r]",
        "Y[Thumb r]",
        "Z[Thumb r]",
    ]


    variable_names_latex = [
    "\\text{hand tip l}_X",
    "\\text{hand tip l}_Y",
    "\\text{hand tip l}_Z",
    "\\text{hand tip r}_X",
    "\\text{hand tip r}_Y",
    "\\text{hand tip r}_Z",
    "\\text{elbow l}_X",
    "\\text{elbow l}_Y",
    "\\text{elbow l}_Z",
    "\\text{elbow r}_X",
    "\\text{elbow r}_Y",
    "\\text{elbow r}_Z",
    "\\text{wrist l}_X",
    "\\text{wrist l}_Y",
    "\\text{wrist l}_Z",
    "\\text{wrist r}_X",
    "\\text{wrist r}_Y",
    "\\text{wrist r}_Z",
    "\\text{thumb l}_X",
    "\\text{thumb l}_Y",
    "\\text{thumb l}_Z",
    "\\text{thumb r}_X",
    "\\text{thumb r}_Y",
    "\\text{thumb r}_Z",
    ]
    X_train  = fix_dataframe(X_train, variable_names)
    X_test   = fix_dataframe(X_test, variable_names)

    class_names = [
        "I have command",
        "All clear",
        "Not clear",
        "Spread wings",
        "Fold wings",
        "Lock wings",
    ]

    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test  = map(fix_class_names, y_test)

    @assert nrow(X_train) == length(y_train) "$(nrow(X_train)), $(length(y_train))"

    y_train = categorical(y_train)
    y_test = categorical(y_test)
    if split == :all
        vcat(X_train, X_test), vcat(y_train, y_test)
    elseif split == :train
        (X_train, y_train)
    elseif split == :test
        (X_test, y_test)
    elseif split == :traintest
        ((X_train, y_train), (X_test,  y_test))
    else
        error("Unexpected value for split parameter: $(split)")
    end
end

const _ARFF_SPACE       = UInt8(' ')
const _ARFF_COMMENT     = UInt8('%')
const _ARFF_AT          = UInt8('@')
const _ARFF_SEP         = UInt8(',')
const _ARFF_NEWLINE     = UInt8('\n')
const _ARFF_NOMSTART    = UInt8('{')
const _ARFF_NOMEND      = UInt8('}')
const _ARFF_ESC         = UInt8('\\')
const _ARFF_MISSING     = UInt8('?')
const _ARFF_RELMARK     = UInt8('\'')

"""
TODO: document this.
"""
function parseARFF(arffstring::String)
    df = DataFrame()
    classes = String[]
    lines = split(arffstring, "\n")
    for i in 1:length(lines)
        line = lines[i]
        # If not empty line or comment
        if !isempty(line)
            if UInt8(line[1]) != _ARFF_COMMENT
                sline = split(line, " ")
                # println(sline[1][1])
                # If the first symbol is @
                if UInt8(sline[1][1]) == _ARFF_AT
                    # If @relation
                    if sline[1][2:end] == "relation"
                        # println("Relation: " * sline[2])
                    end

                    # if sline[1][2:end] == "variable" && sline[2] == "class"
                    #     classes = sline[3][2:end-1]
                    #     println(classes)
                    # end
                # data, first char is '
                elseif UInt8(sline[1][1]) == _ARFF_RELMARK
                    sline[1] = sline[1][2:end]
                    data_and_class = split(sline[1],"\'")
                    string_data = split(data_and_class[1], "\\n")
                    class = data_and_class[2][2:end]

                    if isempty(names(df))
                        for i in 1:length(string_data)
                            insertcols!(df, Symbol("V$(i)") => Array{Float64, 1}[]) # add the variables as 1,2,3,ecc.
                        end
                    end

                    float_data = Dict{Int,Vector{Float64}}()

                    for i in 1:length(string_data)
                        float_data[i] = map(x->parse(Float64,x), split(string_data[i], ","))
                    end

                    # @show float_data


                    push!(df, [float_data[i] for i in 1:length(string_data)])
                    push!(classes, class)
                    # @show data
                    # @show class
                end
            end
        end
    end

    # for i in eachrow(df)
    #   println(typeof(i))
    #   break
    # end
    p = sortperm(eachrow(df), by=x->classes[rownumber(x)])

    return df[p, :], classes[p]
end

"""
TODO: document this.
"""
function fix_dataframe(df, _variablenames = nothing)
    s = unique(size.(df[:,1]))
    @assert length(s) == 1 "$(s)"
    @assert length(s[1]) == 1 "$(s[1])"
    nvars, npoints = length(names(df)), s[1][1]
    old_var_names = names(df)
    X = OrderedDict()

    if isnothing(_variablenames)
        _variablenames = ["V$(i_var)" for i_var in 1:nvars]

    end

    @assert nvars == Base.length(_variablenames)

    for (i_var,var) in enumerate(_variablenames)
        X[Symbol(var)] = [row[i_var] for row in eachrow(df)]
    end

    X = DataFrame(X)
end

"""
    available_datasets()

Return a list of all available dataset names in SoleData.

# Example
```julia
julia> using SoleData.Artifacts
julia> available_datasets()
4-element Vector{String}:
 "epilepsy"
 "hugadb"
 "libras"
 "natops"
```
"""
function available_datasets()::AbstractVector{<:AbstractString}
    dataset_loader_types = InteractiveUtils.subtypes(AbstractLoaderDataset)

    return [name(T()) for T in dataset_loader_types]
end

"""
    get_dataset_loader(dataset_name::AbstractString)

Get the appropriate loader for a dataset by name.

# Arguments
- `dataset_name::AbstractString`: Name of the dataset (e.g., "natops", "libras")

# Returns
The corresponding loader instance.

# Example
```julia
julia> using SoleData.Artifacts
julia> loader = get_dataset_loader("natops")
julia> X, y = load(loader)
```
"""
function get_dataset_loader(dataset_name::AbstractString)::AbstractLoaderDataset
    dataset_name = lowercase(dataset_name)

    for T in subtypes(AbstractLoaderDataset)
        if name(T()) == dataset_name
            return T()
        end
    end

    available = join(available_datasets(), ", ")
    throw(ArgumentError("Unknown dataset: '$dataset_name'. Available datasets: $available"))
end

"""
    load_dataset(dataset_name::AbstractString)::Tuple{<:AbstractDataFrame, <:CategoricalArray}

Load a dataset by name. This is a convenience function that combines `get_dataset_loader` and `load`.

# Arguments
- `dataset_name::AbstractString`: Name of the dataset (e.g., "natops", "libras")

# Returns
A tuple `(X, y)` where:
- `X`: Feature data (AbstractDataFrame)
- `y`: Labels (CategoricalArray)

# Example
```julia
julia> using SoleData.Artifacts
julia> X, y = load_dataset("natops")
```
"""
function load_dataset(dataset_name::AbstractString)::Tuple{<:AbstractDataFrame, <:CategoricalArray}
    loader = get_dataset_loader(dataset_name)
    return load(loader)
end