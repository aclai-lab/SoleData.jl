using SoleData: MultivariateFeature,
                    UnivariateFeature,
                    UnivariateNamedFeature,
                    VariableValue,
                    VariableMin,
                    VariableMax,
                    VariableSoftMin,
                    VariableSoftMax,
                    VariableAvg,
                    i_variable,
                    alpha

import SoleData: computefeature, computeunivariatefeature
using StatsBase: mean

function computefeature(f::MultivariateFeature{U}, featchannel::Any) where {U}
    (f.f(featchannel))::U
end

function computeunivariatefeature(f::UnivariateFeature{U}, varchannel::Union{T,AbstractArray{T}}) where {U,T}
    # (f.f(SoleBase.vectorize(varchannel);))::U
    (f.f(varchannel))::U
end
function computeunivariatefeature(f::UnivariateNamedFeature, varchannel::Union{T,AbstractArray{T}}) where {T}
    return error("Cannot intepret UnivariateNamedFeature on any structure at all.")
end
function computeunivariatefeature(f::VariableValue, varchannel::Union{T,AbstractArray{T}}) where {T}
    (varchannel isa T ? varchannel : first(varchannel))
end
function computeunivariatefeature(f::VariableMin, varchannel::AbstractArray{T}) where {T}
    (minimum(varchannel))
end
function computeunivariatefeature(f::VariableMax, varchannel::AbstractArray{T}) where {T}
    (maximum(varchannel))
end
function computeunivariatefeature(f::VariableSoftMin, varchannel::AbstractArray{T}) where {T}
    SoleBase.softminimum(varchannel, alpha(f))
end
function computeunivariatefeature(f::VariableSoftMax, varchannel::AbstractArray{T}) where {T}
    SoleBase.softmaximum(varchannel, alpha(f))
end
function computeunivariatefeature(f::VariableAvg, varchannel::AbstractArray{T}) where {T}
    (mean(varchannel))
end
function computeunivariatefeature(f::VariableDistance, varchannel::AbstractArray{T}) where {T}
    (distance(f).(varchannel,references(f)) |> minimum)
end

# simplified propositional cases:
function computeunivariatefeature(f::VariableMin, varchannel::T) where {T}
    (minimum(varchannel))
end
function computeunivariatefeature(f::VariableMax, varchannel::T) where {T}
    (maximum(varchannel))
end
function computeunivariatefeature(f::VariableSoftMin, varchannel::T) where {T}
    varchannel
end
function computeunivariatefeature(f::VariableSoftMax, varchannel::T) where {T}
    varchannel
end
function computeunivariatefeature(f::VariableAvg, varchannel::T) where {T}
    varchannel
end
function computeunivariatefeature(f::VariableDistance, varchannel::T) where {T}
    (distance(f).(varchannel,references(f)) |> minimum)
end
