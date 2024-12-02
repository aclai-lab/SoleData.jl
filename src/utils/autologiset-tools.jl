using SoleData.DimensionalDatasets
using SoleData.DimensionalDatasets: UniformFullDimensionalLogiset
using SoleData: ScalarOneStepMemoset, AbstractFullMemoset
using SoleData: naturalconditions


AVAILABLE_RELATIONS = OrderedDict{Symbol,Function}([
    :none       => (d)->AbstractRelation[],
    :IA         => (d)->[globalrel, (d == 1 ? SoleLogics.IARelations  : (d == 2 ? SoleLogics.IA2DRelations  : error("Unexpected dimensionality ($d).")))...],
    :IA3        => (d)->[globalrel, (d == 1 ? SoleLogics.IA3Relations : (d == 2 ? SoleLogics.IA32DRelations : error("Unexpected dimensionality ($d).")))...],
    :IA7        => (d)->[globalrel, (d == 1 ? SoleLogics.IA7Relations : (d == 2 ? SoleLogics.IA72DRelations : error("Unexpected dimensionality ($d).")))...],
    :RCC5       => (d)->[globalrel, SoleLogics.RCC5Relations...],
    :RCC8       => (d)->[globalrel, SoleLogics.RCC8Relations...],
])

mlj_default_relations = nothing

mlj_default_relations_str = "either no relation (adimensional data), " *
    "IA7 interval relations (1- and 2-dimensional data)."
    # , or RCC5 relations " *
    # "(2-dimensional data)."

function defaultrelations(dataset, relations)
    # @show typeof(dataset)
    if dataset isa Union{
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}} where {W,U,FT,FR,L,N},
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}} where {W,U,FT,FR,L,N},
    }
        if relations == mlj_default_relations
            MDT.relations(dataset)
        else
            error("Unexpected dataset type: $(typeof(dataset)).")
        end
    else
        symb = begin
            if relations isa Symbol
                relations
            elseif dimensionality(dataset) == 0
                :none
            elseif dimensionality(dataset) == 1
                :IA7
            elseif dimensionality(dataset) == 2
                :IA7
                # :RCC8
            else
                error("Cannot infer relation set for dimensionality $(repr(dimensionality(dataset))). " *
                    "Dimensionality should be 0, 1 or 2.")
            end
        end

        d = dimensionality(dataset)
        if d == 0
            AVAILABLE_RELATIONS[:none](d)
        else
            AVAILABLE_RELATIONS[symb](d)
        end
    end
end

# Infer relation set from model.relations parameter and the (unimodal) dataset.
function readrelations(model_relations, dataset)
    if model_relations == mlj_default_relations || model_relations isa Symbol
        defaultrelations(dataset, model_relations)
    else
        if dataset isa Union{
            SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}} where {W,U,FT,FR,L,N},
            SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}} where {W,U,FT,FR,L,N},
        }
            rels = model_relations(dataset)
            @assert issubset(rels, MDT.relations(dataset)) "Could not find " *
                "specified relations $(SoleLogics.displaysyntaxvector(rels)) in " *
                "logiset relations $(SoleLogics.displaysyntaxvector(MDT.relations(dataset)))."
            rels
        else
            model_relations(dataset)
        end
    end
end


mlj_default_conditions = nothing

mlj_default_conditions_str = "scalar conditions (test operators ≥ and <) " *
    "on either minimum and maximum feature functions (if dimensional data is provided), " *
    "or the features of the logiset, if one is provided."

function defaultconditions(dataset)
    if dataset isa Union{
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}} where {W,U,FT,FR,L,N},
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}} where {W,U,FT,FR,L,N},
    }
        MDT.metaconditions(dataset)
    elseif dataset isa UniformFullDimensionalLogiset
        vcat([
            [
                ScalarMetaCondition(feature, ≥),
                (all(i_instance->SoleData.nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset)) ?
                    [] :
                    [ScalarMetaCondition(feature, <)]
                )...
            ]
        for feature in features(dataset)]...)
    else
        if all(i_instance->SoleData.nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))
            [identity]
        else
            [minimum, maximum]
        end
    end
end

function readconditions(
    model_conditions,
    model_featvaltype,
    dataset;
    force_i_variables  :: Bool = false,
    fixcallablenans    :: Bool = false,
)
    conditions = begin
        if model_conditions == mlj_default_conditions
            defaultconditions(dataset)
        else
            model_conditions
        end
    end

    if dataset isa Union{
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}} where {W,U,FT,FR,L,N},
        SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}} where {W,U,FT,FR,L,N},
    }
        @assert issubset(conditions, MDT.metaconditions(dataset)) "Could not find " *
            "specified conditions $(SoleLogics.displaysyntaxvector(conditions)) in " *
            "logiset metaconditions $(SoleLogics.displaysyntaxvector(MDT.metaconditions(dataset)))."
        conditions
    else
        # @show typeof(dataset)
        naturalconditions(dataset, conditions, model_featvaltype; force_i_variables, fixcallablenans)
    end
end




# UNI
# AbstractArray -> scalarlogiset -> supportedlogiset
# SupportedLogiset -> supportedlogiset
# AbstractModalLogiset -> supportedlogiset

# MULTI
# SoleData.MultiDataset -> multilogiset
# AbstractDataFrame -> naturalgrouping -> multilogiset
# MultiLogiset -> multilogiset

function autologiset(
    X;
    force_var_grouping::Union{Nothing,AbstractVector{<:AbstractVector}} = nothing,
    downsize = autodownsize(true),
    conditions = autoconditions(nothing),
    featvaltype = Float64, # TODO derive it from X + conditions.
    relations = autorelations(nothing),
    passive_mode = false,
    force_i_variables  :: Bool = false,
    fixcallablenans    :: Bool = false,
)

    if X isa MultiLogiset
        if !isnothing(force_var_grouping)
            @warn "Ignoring var_grouping $(force_var_grouping) (a MultiLogiset was provided)."
        end
        multimodal_X, var_grouping = X, nothing
        return multimodal_X, var_grouping
    end

    # Vector of instance values
    # Matrix instance x variable -> Matrix variable x instance
    if X isa AbstractVector
        X = collect(reshape(X, 1, length(X)))
    elseif X isa AbstractMatrix
        X = collect(X')
    end

    if X isa AbstractArray # Cube
        if !(X isa Union{AbstractVector,AbstractMatrix})
            @warn "AbstractArray of $(ndims(X)) dimensions and size $(size(X)) encountered. " *
                "This will be interpreted as a dataset of $(size(X)[end]) instances, " *
                "$(size(X)[end-1]) variables, and channel size $(size(X)[1:end-2])."
                # "datasets ($(typeof(X)) encountered)"
        end

        X = eachslice(X; dims=ndims(X))
    end

    X = begin
        if X isa AbstractDimensionalDataset
            X = downsize.(eachinstance(X))

            if !passive_mode
                @info "Precomputing logiset..."
                metaconditions = readconditions(conditions, featvaltype, X; force_i_variables, fixcallablenans)
                features = unique(SoleData.feature.(metaconditions))
                scalarlogiset(X, features;
                    use_onestep_memoization = true,
                    conditions = metaconditions,
                    relations = readrelations(relations, X),
                    print_progress = (ninstances(X) > 500)
                )
            else
                MultiData.dimensional2dataframe(X)
            end
        # elseif SoleData.hassupports(X)
        #     X
        elseif X isa AbstractModalLogiset
            SupportedLogiset(X;
                use_onestep_memoization = true,
                conditions = readconditions(conditions, featvaltype, X; force_i_variables, fixcallablenans),
                relations = readrelations(relations, X)
            )
        elseif X isa AbstractMultiDataset
            X
        elseif Tables.istable(X)
            DataFrame(X)
        else
            X
        end
    end

    # @show X
    # @show collect.(X)
    # readline()

    # DataFrame -> MultiDataset + variable grouping (needed for printing)
    X, var_grouping = begin
        if X isa AbstractDataFrame

            allowedcoltypes = Union{Real,AbstractArray{<:Real,0},AbstractVector{<:Real},AbstractMatrix{<:Real}}
            wrong_columns = filter(((colname,c),)->!(eltype(c) <: allowedcoltypes), collect(zip(names(X), eachcol(X))))
            @assert length(wrong_columns) == 0 "Invalid columns " *
                "encountered: `$(join(first.(wrong_columns), "`, `", "` and `"))`. $(MDT).jl only allows " *
                "variables that are `Real` and `AbstractArray{<:Real,N}` with N ∈ {0,1,2}. " *
                "Got: `$(join(eltype.(last.(wrong_columns)), "`, `", "` and `"))`" * (length(wrong_columns) > 1 ? ", respectively" : "") * "."

            var_grouping = begin
                if isnothing(force_var_grouping)
                    var_grouping = SoleData.naturalgrouping(X; allow_variable_drop = true)
                    if !(length(var_grouping) == 1 && length(var_grouping[1]) == ncol(X))
                        @info "Using variable grouping:\n" *
                            # join(map(((i_mod,variables),)->"[$i_mod] -> [$(join(string.(variables), ", "))]", enumerate(var_grouping)), "\n")
                            join(map(((i_mod,variables),)->"\t{$i_mod} => $(Tuple(variables))", enumerate(var_grouping)), "\n")
                    end
                    var_grouping
                else
                    @assert force_var_grouping isa AbstractVector{<:AbstractVector} "$(typeof(force_var_grouping))"
                    force_var_grouping
                end
            end

            md = MultiDataset(X, var_grouping)

            # Downsize
            md = MultiDataset([begin
                mod, varnames = dataframe2dimensional(mod)
                mod = downsize.(eachinstance(mod))
                SoleData.dimensional2dataframe(mod, varnames)
            end for mod in eachmodality(md)])

            md, var_grouping
        else
            X, nothing
        end
    end

    # println(X)
    # println(modality(X, 1))
    multimodal_X = begin
        if X isa SoleData.AbstractMultiDataset
            if !passive_mode || !SoleData.ismultilogiseed(X)
                @info "Precomputing logiset..."
                MultiLogiset([begin
                        _metaconditions = readconditions(conditions, featvaltype, mod; force_i_variables, fixcallablenans)
                        features = unique(SoleData.feature.(_metaconditions))
                        # @show _metaconditions
                        # @show features
                        scalarlogiset(mod, features;
                            use_onestep_memoization = true,
                            conditions = _metaconditions,
                            relations = readrelations(relations, mod),
                            print_progress = (ninstances(X) > 500)
                        )
                    end for mod in eachmodality(X)
                ])
            else
                X
            end
        elseif X isa AbstractModalLogiset
            MultiLogiset(X)
        elseif X isa MultiLogiset
            X
        else
            error("Unexpected dataset type: $(typeof(X)). Allowed dataset types are " *
                "AbstractArray, AbstractDataFrame, " *
                "SoleData.AbstractMultiDataset and SoleData.AbstractModalLogiset.")
        end
    end

    return (multimodal_X, var_grouping)
end


function autorelations(relations)
    warning = ""

    if !(isnothing(relations) ||
        relations isa Symbol && relations in keys(AVAILABLE_RELATIONS) ||
        relations isa Vector{<:AbstractRelation} ||
        relations isa Function
    )
        warning *= "relations should be in $(collect(keys(AVAILABLE_RELATIONS))) " *
            "or a vector of SoleLogics.AbstractRelation's, " *
            "but $(relations) " *
            "was provided. Defaulting to $(mlj_default_relations_str).\n"
        relations = nothing
    end

    isnothing(relations)                      && (relations  = mlj_default_relations)
    relations isa Vector{<:AbstractRelation}  && (relations  = relations)
    return relations, warning
end

function autoconditions(conditions)
    warning = ""

    if !(isnothing(conditions) ||
        conditions isa Vector{<:Union{SoleData.VarFeature,Base.Callable}} ||
        conditions isa Vector{<:Tuple{Base.Callable,Integer}} ||
        conditions isa Vector{<:Tuple{TestOperator,<:Union{SoleData.VarFeature,Base.Callable}}} ||
        conditions isa Vector{<:SoleData.ScalarMetaCondition}
    )
        warning *= "conditions should be either:" *
            "a) a vector of features (i.e., callables to be associated to all variables, or SoleData.VarFeature objects);\n" *
            "b) a vector of tuples (callable,var_id);\n" *
            "c) a vector of tuples (test_operator,features);\n" *
            "d) a vector of SoleData.ScalarMetaCondition;\n" *
            "but $(conditions) " *
            "was provided. Defaulting to $(mlj_default_conditions_str).\n"
        conditions = nothing
    end

    isnothing(conditions) && (conditions  = mlj_default_conditions)
    return conditions, warning
end

function autodownsize(m)
    warning = ""

    downsize = begin
        if m.downsize == true
            make_downsizing_function(m)
        elseif m.downsize == false
            identity
        elseif m.downsize isa NTuple{N,Integer} where N
            make_downsizing_function(m.downsize)
        elseif m.downsize isa Function
            m.downsize
        else
            error("Unexpected value for `downsize` encountered: $(m.downsize)")
        end
    end

    return downsize, warning
end





using StatsBase
using StatsBase: mean
using SoleBase: movingwindow
using SoleData: AbstractDimensionalDataset

DOWNSIZE_MSG = "If this process gets killed, please downsize your dataset beforehand."

function make_downsizing_function(channelsize::NTuple)
    return function downsize(instance)
        return moving_average(instance, channelsize)
    end
end




function make_downsizing_function(::Val{1})
    function downsize(instance)
        channelsize = MultiData.instance_channelsize(instance)
        nvariables = MultiData.instance_nvariables(instance)
        channelndims = length(channelsize)
        if channelndims == 1
            n_points = channelsize[1]
            if nvariables > 30 && n_points > 100
                # @warn "Downsizing series $(n_points) points to $(100) points ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, 100)
            elseif n_points > 150
                # @warn "Downsizing series $(n_points) points to $(150) points ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, 150)
            end
        elseif channelndims == 2
            if nvariables > 30 && prod(channelsize) > prod((7,7),)
                new_channelsize = min.(channelsize, (7,7))
                # @warn "Downsizing image of size $(channelsize) to $(new_channelsize) pixels ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, new_channelsize)
            elseif prod(channelsize) > prod((10,10),)
                new_channelsize = min.(channelsize, (10,10))
                # @warn "Downsizing image of size $(channelsize) to $(new_channelsize) pixels ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, new_channelsize)
            end
        end
        instance
    end
end

function make_downsizing_function(::Val{2})
    function downsize(instance)
        channelsize = MultiData.instance_channelsize(instance)
        nvariables = MultiData.instance_nvariables(instance)
        channelndims = length(channelsize)
        if channelndims == 1
            n_points = channelsize[1]
            if nvariables > 30 && n_points > 100
                # @warn "Downsizing series $(n_points) points to $(100) points ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, 100)
            elseif n_points > 150
                # @warn "Downsizing series $(n_points) points to $(150) points ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, 150)
            end
        elseif channelndims == 2
            if nvariables > 30 && prod(channelsize) > prod((4,4),)
                new_channelsize = min.(channelsize, (4,4))
                # @warn "Downsizing image of size $(channelsize) to $(new_channelsize) pixels ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, new_channelsize)
            elseif prod(channelsize) > prod((7,7),)
                new_channelsize = min.(channelsize, (7,7))
                # @warn "Downsizing image of size $(channelsize) to $(new_channelsize) pixels ($(nvariables) variables). $DOWNSIZE_MSG"
                instance = moving_average(instance, new_channelsize)
            end
        end
        instance
    end
end

# TODO move to MultiData/SoleData

_mean(::Type{T}, vals::AbstractArray{T}) where {T<:Number} = StatsBase.mean(vals)
_mean(::Type{T1}, vals::AbstractArray{T2}) where {T1<:AbstractFloat,T2<:Integer} = T1(StatsBase.mean(vals))
_mean(::Type{T1}, vals::AbstractArray{T2}) where {T1<:Integer,T2<:AbstractFloat} = round(T1, StatsBase.mean(vals))

# # 1D
# function moving_average(
#     instance::AbstractArray{T,1};
#     kwargs...
# ) where {T<:Union{Nothing,Number}}
#     npoints = length(instance)
#     return [_mean(T, instance[idxs]) for idxs in movingwindow(npoints; kwargs...)]
# end

# # 1D
# function moving_average(
#     instance::AbstractArray{T,1},
#     nwindows::Integer,
#     relative_overlap::AbstractFloat = .5,
# ) where {T<:Union{Nothing,Number}}
#     npoints = length(instance)
#     return [_mean(T, instance[idxs]) for idxs in movingwindow(npoints; nwindows = nwindows, relative_overlap = relative_overlap)]
# end

# 1D-instance
function moving_average(
    instance::AbstractArray{T,2},
    nwindows::Union{Integer,Tuple{Integer}},
    relative_overlap::AbstractFloat = .5,
) where {T<:Union{Nothing,Number}}
    nwindows = nwindows isa Tuple{<:Integer} ? nwindows[1] : nwindows
    npoints, n_variables = size(instance)
    new_instance = similar(instance, (nwindows, n_variables))
    for i_variable in 1:n_variables
        new_instance[:, i_variable] .= [_mean(T, instance[idxs, i_variable]) for idxs in movingwindow(npoints; nwindows = nwindows, relative_overlap = relative_overlap)]
    end
    return new_instance
end

# 2D-instance
function moving_average(
    instance::AbstractArray{T,3},
    new_channelsize::Tuple{Integer,Integer},
    relative_overlap::AbstractFloat = .5,
) where {T<:Union{Nothing,Number}}
    n_instance, n_Y, n_variables = size(instance)
    windows_1 = movingwindow(n_instance; nwindows = new_channelsize[1], relative_overlap = relative_overlap)
    windows_2 = movingwindow(n_Y; nwindows = new_channelsize[2], relative_overlap = relative_overlap)
    new_instance = similar(instance, (new_channelsize..., n_variables))
    for i_variable in 1:n_variables
        new_instance[:, :, i_variable] .= [_mean(T, instance[idxs1, idxs2, i_variable]) for idxs1 in windows_1, idxs2 in windows_2]
    end
    return new_instance
end

function moving_average(dataset::AbstractDimensionalDataset, args...; kwargs...)
    return map(instance->moving_average(instance, args...; kwargs...), eachinstance(dataset))
end



# if model.check_conditions == true
#     check_conditions(model.conditions)
# end
# function check_conditions(conditions)
#     if isnothing(conditions)
#         return
#     end
#     # Check that feature extraction functions are scalar
#     wrong_conditions = filter((f)->begin
#             !all(
#                 (ch)->!(f isa Base.Callable) ||
#                     (ret = f(ch); isa(ret, Real) && typeof(ret) == eltype(ch)),
#                 [collect(1:10), collect(1.:10.)]
#             )
#         end, conditions)
#     @assert length(wrong_conditions) == 0 "When specifying feature extraction functions " *
#         "for inferring `conditions`, please specify " *
#         "scalar functions accepting an object of type `AbstractArray{T}` " *
#         "and returning an object of type `T`, with `T<:Real`. " *
#         "Instead, got wrong feature functions: $(wrong_conditions)."
# end

