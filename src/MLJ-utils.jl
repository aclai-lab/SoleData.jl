module MLJUtils

using CategoricalArrays
using MLJBase

export fix_y

function fix_y(y)
    if isnothing(y)
        return nothing, nothing
    end
    is_classification = (eltype(MLJBase.scitype(y)) != Continuous)
    classes_seen = begin
        if is_classification
            y isa CategoricalArray ? filter(in(unique(y)), MLJBase.classes(y)) : unique(y)
        else
            nothing
        end
    end
    y = begin
        if is_classification
            Vector{String}(string.(y))
        else
            Vector{Float64}(y)
        end
    end
    y, classes_seen
end

# function is_classification(y)
#     !isnothing(y) && eltype(MLJBase.scitype(y)) != Continuous
# end

end
