
# # https://github.com/garrison/UniqueVectors.jl/issues/24
# function Base.in(item, uv::UniqueVector)
#     @warn "Base.in(::$(typeof(item)), ::$(typeof(uv))) is defined by type piracy from UniqueVectors.jl. This method is deprecating."
#     haskey(uv.lookup, item)
# end
# function Base.findfirst(p::UniqueVectors.EqualTo, uv::UniqueVector)
#     @warn "Base.findfirst(::$(typeof(p)), ::$(typeof(uv))) is defined by type piracy from UniqueVectors.jl. This method is deprecating."
#     get(uv.lookup, p.x, nothing)
# end
