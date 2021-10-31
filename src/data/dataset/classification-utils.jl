"""
TODO: major review
"""


"""
    class(cmfd, i)

Get the `i`-th class names of `cmfd` ClassificationMultiFrameDataset.
"""
function class(cmfd::AbstractClassificationMultiFrameDataset, i::Integer)
    return classes(cmfd)[i]
end

"""
    classes(cmfd)

Get the classes names of `cmfd` ClassificationMultiFrameDataset.
"""
function classes(cmfd::AbstractClassificationMultiFrameDataset)
    return Symbol.(names(data(cmfd)))[classes_descriptor(cmfd)]
end

"""
    nclasses(cmfd)

Get the number of classes of `cmfd` ClassificationMultiFrameDataset.
"""
nclasses(cmfd::AbstractClassificationMultiFrameDataset) = length(classes(cmfd))

function _print_class_domain(set::AbstractSet)
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

"""
    classdomain(cmfd, i)

Get the domain of `i`-th class of `cmfd` ClassificationMultiFrameDataset.
"""
function classdomain(cmfd::AbstractClassificationMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nclasses(cmfd) "Index ($i) must be a valid class number " *
        "(1:$(nclasses(mfd)))"

    return Set(data(cmfd)[:,i])
end

"""
    addclass!(cmfd, i)

Set the `i`-th attribute of `cmfd` ClassificationMultiFrameDataset as class.
"""
function addclass!(cmfd::AbstractClassificationMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(cmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(mfd)))"

    if _is_attribute_in_frames(cmfd, i)
        # TODO: consider enforcing this instead of just warning
        @warn "Setting as class an attribute used in a frame: this is discouraged and " *
            "probably will not allowed in future versions"
    end

    if i in classes_descriptor(cmfd)
        @info "Attribute at index $(i) was already a class"
    else
        push!(classes_descriptor(cmfd), i)
    end

    return cmfd
end

"""
    removeclass!(cmfd, i)

Remove the `i`-th attribute of `cmfd` ClassificationMultiFrameDataset from classes.
"""
function removeclass!(cmfd::AbstractClassificationMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(cmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(mfd)))"

    index = findfirst(isequal(i), classes_descriptor(cmfd))

    if isnothing(index)
        @info "Attribute at index $(i) was not a class"
    else
        deleteat!(classes_descriptor(cmfd), index)
    end

    return cmfd
end

function spareattributes(cmfd::ClassificationMultiFrameDataset)
    filter!(attr -> !(attr in classes_descriptor(cmfd)), spareattributes(dataset(cmfd)))
end
