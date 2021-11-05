
# -------------------------------------------------------------
# RegressionMultiFrameDataset

"""
TODO: docs
"""
struct RegressionMultiFrameDataset <: AbstractRegressionMultiFrameDataset
    regressor_descriptor::AbstractVector{Integer}
    mfd::AbstractMultiFrameDataset

    function RegressionMultiFrameDataset(
        regressors_descriptor::AbstractVector{<:Integer},
        mfd::AbstractMultiFrameDataset
    )
        for i in regressors_descriptor
            if _is_attribute_in_frames(mfd, i)
                # TODO: consider enforcing this instead of just warning
                @warn "Setting as regressor an attribute used in a frame: this is discouraged " *
                    "and probably will not allowed in future versions"
            end
        end

        return new(regressors_descriptor, mfd)
    end
end

# -------------------------------------------------------------
# RegressionMultiFrameDataset - accessors

descriptor(rmfd::RegressionMultiFrameDataset) = descriptor(rmfd.mfd)
frame_descriptor(rmfd::RegressionMultiFrameDataset) = descriptor(rmfd)
data(rmfd::RegressionMultiFrameDataset) = data(rmfd.mfd)
regressors_descriptor(rmfd::RegressionMultiFrameDataset) = rmfd.regressor_descriptor
dataset(rmfd::RegressionMultiFrameDataset) = rmfd.mfd

# -------------------------------------------------------------
# RegressionMultiFrameDataset - informations

function show(io::IO, rmfd::RegressionMultiFrameDataset)
    println(io, "● RegressionMultiFrameDataset")
    println(io, "   ├─ regressors")

    if nregressors(rmfd) > 0
        for i in 1:(nregressors(rmfd)-1)
            println(io, "   │   ├─ $(regressor(rmfd, i)): $(_print_regressor_domain(regressordomain(rmfd, i)))")
        end
        println(io, "   │   └─ $(regressor(rmfd, nregressors(rmfd))): " *
            "$(_print_regressor_domain(regressordomain(rmfd, nregressors(rmfd))))")
    else
        println(io, "   │   └─ no regressor selected")
    end
    println(io, "   └─ dimensions: $(dimension(rmfd))")

    for (i, frame) in enumerate(rmfd)
        println(io, "- Frame $(i) / $(nframes(rmfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end

    spare_attrs = spareattributes(rmfd)
    if length(spare_attrs) > 0
        spare_df = @view data(rmfd)[:,spare_attrs]
        println(io, "- Spare attributes")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
end

# -------------------------------------------------------------
# RegressionMultiFrameDataset - utils

function _empty(rmfd::RegressionMultiFrameDataset)
    return RegressionMultiFrameDataset(
        deepcopy(descriptor(rmfd)),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(data(rmfd)))])
    )
end
