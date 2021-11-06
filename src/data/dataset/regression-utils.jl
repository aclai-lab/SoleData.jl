"""
TODO: major review
"""

"""
    regressor(rmfd, i)

Get the `i`-th regressor names of `rmfd` RegressionMultiFrameDataset.
"""
function regressor(rmfd::AbstractRegressionMultiFrameDataset, i::Integer)
    return regressors(rmfd)[i]
end

"""
    regressors(rmfd)

Get the regressors names of `rmfd` RegressionMultiFrameDataset.
"""
function regressors(rmfd::AbstractRegressionMultiFrameDataset)
    return Symbol.(names(data(rmfd)))[regressors_descriptor(rmfd)]
end

"""
    nregressors(rmfd)

Get the number of regressors of `rmfd` RegressionMultiFrameDataset.
"""
nregressors(rmfd::AbstractRegressionMultiFrameDataset) = length(regressors(rmfd))

_print_regressor_domain(dom::Tuple) = "($(dom[1]) - $(dom[end]))"

"""
    regressordomain(rmfd, i)

Get the domain of `i`-th regressor of `rmfd` RegressionMultiFrameDataset.
"""
function regressordomain(rmfd::AbstractRegressionMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nregressors(rmfd) "Index ($i) must be a valid regressor number " *
        "(1:$(nregressors(mfd)))"

    return extrema(data(rmfd)[:,i])
end

"""
    addregressor!(rmfd, i)

Set the `i`-th attribute of `rmfd` RegressionMultiFrameDataset as regressor.
"""
function addregressor!(rmfd::AbstractRegressionMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(rmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(mfd)))"

    if _is_attribute_in_frames(rmfd, i)
        # TODO: consider enforcing this instead of just warning
        @warn "Setting as regressor an attribute used in a frame: this is discouraged and " *
            "probably will not allowed in future versions"
    end

    if i in regressors_descriptor(rmfd)
        @info "Attribute at index $(i) was already a regressor"
    else
        push!(regressors_descriptor(rmfd), i)
    end

    return rmfd
end

"""
    removeregressor!(rmfd, i)

Remove the `i`-th attribute of `rmfd` RegressionMultiFrameDataset from regressors.
"""
function removeregressor!(rmfd::AbstractRegressionMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(rmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(mfd)))"

    index = findfirst(isequal(i), regressors_descriptor(rmfd))

    if isnothing(index)
        @info "Attribute at index $(i) was not a regressor"
    else
        deleteat!(regressors_descriptor(rmfd), index)
    end

    return rmfd
end

function spareattributes(rmfd::RegressionMultiFrameDataset)
    filter!(attr -> !(attr in regressors_descriptor(rmfd)), spareattributes(dataset(rmfd)))
end
