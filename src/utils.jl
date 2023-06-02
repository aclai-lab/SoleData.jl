
const __note_about_utils = "
!!! note

    It is important to consider that this function is intended for internal use only.

    It assumes that any check is performed prior its call (e.g., check if the index of an
    variable is valid or not).
"

# -------------------------------------------------------------
# AbstractMultiModalDataset - utils

"""
    _empty(md)

Return a copy of a multimodal dataset with no instances.

Note: since the returned AbstractMultiModalDataset will be empty its columns types will be
`Any`.

$(__note_about_utils)
"""
function _empty(md::AbstractMultiModalDataset)
    warn("This method for `_empty` is extremely not efficent especially for " *
        "large datasets: consider providing a custom method for _empty(::$(typeof(md))).")
    return _empty!(deepcopy(md))
end
"""
    _empty!(md)

Remove all instances from a multimodal dataset.

Note: since the AbstractMultiModalDataset will be empty its columns types will become of
type `Any`.

$(__note_about_utils)
"""
function _empty!(md::AbstractMultiModalDataset)
    return removeinstances!(md, 1:nisnstances(md))
end

"""
    _same_variables(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same variables.

$(__note_about_utils)
"""
function _same_variables(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return isequal(
        Dict{Symbol,DataType}(Symbol.(names(data(md1))) .=> eltype.(eachcol(data(md1)))),
        Dict{Symbol,DataType}(Symbol.(names(data(md2))) .=> eltype.(eachcol(data(md2))))
    )
end

"""
    _same_dataset(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same inner DataFrame regardless of
the positioning of their columns.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same variables use [`_same_variables`](@ref) instead.

$(__note_about_utils)
"""
function _same_dataset(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    if !_same_variables(md1, md2) || ninstances(md1) != ninstances(md2)
        return false
    end

    md1_vars = Symbol.(names(data(md1)))
    md2_vars = Symbol.(names(data(md2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), md2_vars) for name in md1_vars]

    return data(md1) == data(md2)[:,unmixed_indices]
end

"""
    _same_grouped_variables(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same modalities regardless of the
positioning of their columns.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same variables use [`_same_variables`](@ref) instead.

$(__note_about_utils)
"""
function _same_grouped_variables(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    if !_same_variables(md1, md2)
        return false
    end

    if nmodalities(md1) != nmodalities(md2) ||
            [nvariables(f) for f in md1] != [nvariables(f) for f in md2]
        return false
    end

    md1_vars = Symbol.(names(data(md1)))
    md2_vars = Symbol.(names(data(md2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), md2_vars) for name in md1_vars]

    for i in 1:nmodalities(md1)
        if grouped_variables(md1)[i] != Integer[unmixed_indices[j]
                for j in grouped_variables(md2)[i]]
            return false
        end
    end

    return data(md1) == data(md2)[:,unmixed_indices]
end

"""
    _same_label_descriptor(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same labels regardless of the
positioning of their columns.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same variables use [`_same_label_names`](@ref) instead.

$(__note_about_utils)
"""
function _same_label_descriptor(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return true
end
function _same_label_descriptor(
    lmd1::AbstractLabeledMultiModalDataset,
    lmd2::AbstractLabeledMultiModalDataset
)
    !_same_label_names(lmd1, lmd2) && return false;

    lmd1_lbls = labels(lmd1)
    lmd2_lbls = labels(lmd2)
    unmixed_indices = [findfirst(x -> isequal(x, name), Symbol.(names(data(lmd2))))
        for name in lmd1_lbls]

    return data(lmd1)[:,lmd1_lbls] == data(lmd2)[:,unmixed_indices]
end

"""
    _same_label_names(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same label names regardless of the
positioning of their columns.

Note: the check will not be performed against the instances; if the intent is to check
whether the two datasets have the same labels use [`_same_label_descriptor`](@ref) instead.

$(__note_about_utils)
"""
function _same_label_names(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return true
end
function _same_label_names(
    lmd1::AbstractLabeledMultiModalDataset,
    lmd2::AbstractLabeledMultiModalDataset
)
    return Set(labels(lmd1)) == Set(labels(lmd2))
end

"""
    _same_instances(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same instances regardless of their
order.

$(__note_about_utils)
"""
function _same_instances(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    if !_same_variables(md1, md2) || ninstances(md1) != ninstances(md2)
        return false
    end

    return md1 ⊆ md2 && md2 ⊆ md1
end

"""
    _same_md(md1, md2)

Determine whether two AbstractMultiModalDatasets have the same inner DataFrame and modalities,
regardless of the ordering of the columns of their DataFrames.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same variables use [`_same_variables`](@ref) instead.

$(__note_about_utils)
"""
function _same_md(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    if !_same_variables(md1, md2) || ninstances(md1) != ninstances(md2)
        return false
    end

    if nmodalities(md1) != nmodalities(md2) ||
            [nvariables(f) for f in md1] != [nvariables(f) for f in md2]
        return false
    end

    md1_vars = Symbol.(names(data(md1)))
    md2_vars = Symbol.(names(data(md2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), md2_vars) for name in md1_vars]

    if data(md1) != data(md2)[:,unmixed_indices]
        return false
    end

    for i in 1:nmodalities(md1)
        if grouped_variables(md1)[i] != Integer[unmixed_indices[j]
                for j in grouped_variables(md2)[i]]
            return false
        end
    end

    return true
end

"""
    _name2index(df, variable_name)

Return the index of the variable named `variable_name`.

If the variable does not exist `0` is returned.


    _name2index(df, variable_names)

Return the indices of the variables named `variable_names`.

If an variable does not exist, the returned Vector contains `0`(-es).

$(__note_about_utils)
"""
function _name2index(df::AbstractDataFrame, variable_name::Symbol)
    return columnindex(df, variable_name)
end
function _name2index(md::AbstractMultiModalDataset, variable_name::Symbol)
    return columnindex(data(md), variable_name)
end
function _name2index(df::AbstractDataFrame, variable_names::AbstractVector{Symbol})
    return [_name2index(df, var_name) for var_name in variable_names]
end
function _name2index(
    md::AbstractMultiModalDataset,
    variable_names::AbstractVector{Symbol}
)
    return [_name2index(md, var_name) for var_name in variable_names]
end

"""
    _is_variable_in_modalities(md, i)

Check if `i`-th variable is used in any modality or not.

Alternatively to the index the `variable_name` can be passed as second argument.

$(__note_about_utils)
"""
function _is_variable_in_modalities(md::AbstractMultiModalDataset, i::Integer)
    return i in cat(grouped_variables(md)...; dims = 1)
end
function _is_variable_in_modalities(md::AbstractMultiModalDataset, variable_name::Symbol)
    return _is_variable_in_modalities(md, _name2index(md, variable_name))
end

function _prettyprint_header(io::IO, md::AbstractMultiModalDataset)
    println(io, "● $(typeof(md))")
    println(io, "   └─ dimensions: $(dimension(md))")
end

function _prettyprint_modalities(io::IO, md::AbstractMultiModalDataset)
    for (i, modality) in enumerate(md)
        println(io, "- Modality $(i) / $(nmodalities(md))")
        println(io, "   └─ dimension: $(dimension(modality))")
        println(io, modality)
    end
end

function _prettyprint_sparevariables(io::IO, md::AbstractMultiModalDataset)
    spare_vars = sparevariables(md)
    if length(spare_vars) > 0
        spare_df = @view data(md)[:,spare_vars]
        println(io, "- Spare variables")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
end

function _prettyprint_domain(set::AbstractSet)
    vec = collect(set)
    result = "{ "

    for i in 1:length(vec)
        result *= string(vec[i])
        if i != length(vec)
            result *= ","
        end
        result *= " "
    end

    result *= "}"
end
_prettyprint_domain(dom::Tuple) = "($(dom[1]) - $(dom[end]))"

function _prettyprint_labels(io::IO, lmd::AbstractMultiModalDataset)
    println(io, "   ├─ labels")
    if nlabelingvariables(lmd) > 0
        lbls = labels(lmd)
        for i in 1:(length(lbls)-1)
            println(io, "   │   ├─ $(lbls[i]): " *
                "$(labeldomain(lmd, i))")
        end
        println(io, "   │   └─ $(lbls[end]): " *
            "$(labeldomain(lmd, length(lbls)))")
    else
        println(io, "   │   └─ no label selected")
    end
    println(io, "   └─ dimensions: $(dimension(lmd))")
end

"""
    paa(x; f = identity, t = (1, 0, 0))

Piecewise Aggregate Approximation

Apply `f` function to each dimension of `x` array divinding it in `t[1]` windows taking
`t[2]` extra points left and `t[3]` extra points right.

Note: first window will always consider `t[2] = 0` and last one will always consider
`t[3] = 0`.
"""
function paa(
    x::AbstractArray{T};
    f::Function = identity,
    t::AbstractVector{<:NTuple{3,Integer}} = [(1, 0, 0)]
) where {T <: Real}
    @assert ndims(x) == length(t) "Mismatching dims $(ndims(x)) != $(length(t)): " *
        "length(t) has to be equal to ndims(x)"

    N = length(x)
    n_chunks = t[1][1]

    @assert 1 ≤ n_chunks && n_chunks ≤ N "The number of chunks must be in [1,$(N)]"
    @assert 0 ≤ t[1][2] ≤ floor(N/n_chunks) && 0 ≤ t[1][3] ≤ floor(N/n_chunks)

    z = Array{Float64}(undef, n_chunks)
    # TODO Float64? solve this? any better ideas?
    Threads.@threads for i in collect(1:n_chunks)
        l = ceil(Int, (N*(i-1)/n_chunks) + 1)
        h = ceil(Int, N*i/n_chunks)
        if i == 1
            h = h + t[1][3]
        elseif i == n_chunks
            l = l - t[1][2]
        else
            h = h + t[1][3]
            l = l - t[1][2]
        end

        z[i] = f(x[l:h])
    end

    return z
end

"""
    linearize_data(d)

Linearize dimensional object `d`.
"""
linearize_data(d::Any) = d
linearize_data(d::AbstractVector) = d
linearize_data(d::AbstractMatrix) = reshape(m', 1, :)[:]
function linearize_data(d::AbstractArray)
    return throw(ErrorExcpetion("Still can't linearize data of dimension > 2"))
end
# TODO: more linearizations

"""
    unlinearize_data(d, dims)

Unlinearize Vector `d` using dimensions `dims`.
"""
unlinearize_data(d::Any, dims::Tuple{}) = d
function unlinearize_data(d::AbstractVector, dims::Tuple{})
    return length(d) ≤ 1 ? d[1] : collect(d)
end
function unlinearize_data(d::AbstractVector, dims::NTuple{1,<:Integer})
    return collect(d)
end
function unlinearize_data(d::AbstractVector, dims::NTuple{2,<:Integer})
    return collect(reshape(d, dims)')
end
function unlinearize_data(d::AbstractVector, dims::NTuple{N,<:Integer}) where {N<:Integer}
    # TODO: implement generic way to unlinearize data
    throw(ErrorException("Unlinearization of data to $(dims) still not implemented"))
end
