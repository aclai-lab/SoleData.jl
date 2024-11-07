
function islogiseed(
    dataset::NamedTuple,
)
    true
end

function frame(
    dataset::NamedTuple,
    i_instance::Integer
)
    # dataset_dimensional, varnames = dataframe2dimensional(dataset; dry_run = true)
    # FullDimensionalFrame(channelsize(dataset_dimensional, i_instance))
    column = first(X)
    # frame(column, i_instance)
    v = column[i_instance]
    !(v isa Array) ? OneWorld() : FullDimensionalFrame(size(v))
end

# # Note: used in naturalgrouping.
# function frame(
#     dataset::NamedTuple,
#     column::Vector,
#     i_instance::Integer
# )
#     v = [column[i_instance] for column in values(Tables.columns(X))]
#     !(eltype(v) isa Array) ? OneWorld() : FullDimensionalFrame(size(v))
# end
varnames(X::NamedTuple) = keys(X)
############################################################################################
