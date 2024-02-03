using SoleData: MultivariateFeature,
                    UnivariateFeature,
                    UnivariateNamedFeature,
                    UnivariateValue,
                    UnivariateMin,
                    UnivariateMax,
                    UnivariateSoftMin,
                    UnivariateSoftMax,
                    i_variable,
                    alpha

import SoleData: computefeature, computeunivariatefeature

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
function computeunivariatefeature(f::UnivariateValue, varchannel::Union{T,AbstractArray{T}}) where {T}
    (varchannel isa T ? varchannel : first(varchannel))
end
function computeunivariatefeature(f::UnivariateMin, varchannel::AbstractArray{T}) where {T}
    (minimum(varchannel))
end
function computeunivariatefeature(f::UnivariateMax, varchannel::AbstractArray{T}) where {T}
    (maximum(varchannel))
end
function computeunivariatefeature(f::UnivariateSoftMin, varchannel::AbstractArray{T}) where {T}
    SoleBase.softminimum(varchannel, alpha(f))
end
function computeunivariatefeature(f::UnivariateSoftMax, varchannel::AbstractArray{T}) where {T}
    SoleBase.softmaximum(varchannel, alpha(f))
end

# simplified propositional cases:
function computeunivariatefeature(f::UnivariateMin, varchannel::T) where {T}
    (minimum(varchannel))
end
function computeunivariatefeature(f::UnivariateMax, varchannel::T) where {T}
    (maximum(varchannel))
end
function computeunivariatefeature(f::UnivariateSoftMin, varchannel::T) where {T}
    varchannel
end
function computeunivariatefeature(f::UnivariateSoftMax, varchannel::T) where {T}
    varchannel
end
