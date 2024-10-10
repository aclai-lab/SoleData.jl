using ProgressMeter
using SoleData: AbstractMultiDataset
import SoleData: ninstances, nvariables, nmodalities, eachmodality, displaystructure
import SoleData: instances, concatdatasets

function islogiseed(dataset)
    false
    # return error("Please, provide method islogiseed(dataset::$(typeof(dataset))).")
end
function initlogiset#(dataset, features)
    # return error("Please, provide method initlogiset(dataset::$(typeof(dataset)), features::$(typeof(features))).")
end
function ninstances#(dataset)
    # return error("Please, provide method ninstances(dataset::$(typeof(dataset))).")
end
function nvariables#(dataset)
    # return error("Please, provide method nvariables(dataset::$(typeof(dataset))).")
end
function frame#(dataset, i_instance::Integer)
    # return error("Please, provide method frame(dataset::$(typeof(dataset)), i_instance::Integer).")
end
function featvalue#(feature::AbstractFeature, dataset, i_instance::Integer, w)
    # return error("Please, provide method featvalue(feature::$(typeof(feature)), dataset::$(typeof(dataset)), i_instance::Integer, w::$(typeof(w))).")
end
function vareltype#(dataset, i_variable)
    # return error("Please, provide method vareltype(dataset::$(typeof(dataset)), i_variable::Integer).")
end

function allworlds(dataset, i_instance::Integer)
    allworlds(frame(dataset, i_instance))
end

# Multimodal dataset interface
function ismultilogiseed(dataset)
    false
end
function nmodalities#(dataset)
    # return error("Please, provide method nmodalities(dataset::$(typeof(dataset))).")
end
function eachmodality#(dataset)
    # return error("Please, provide method eachmodality(dataset::$(typeof(dataset))).")
end

function modality(dataset, i_modality)
    eachmodality(dataset)[i_modality]
end

function ismultilogiseed(dataset::MultiLogiset)
    true
end
function ismultilogiseed(dataset::AbstractMultiDataset)
    true
end

function ismultilogiseed(dataset::Union{AbstractVector,Tuple})
    length(dataset) > 0 && all(islogiseed, dataset) # && allequal(ninstances, eachmodality(dataset))
end
function nmodalities(dataset::Union{AbstractVector,Tuple})
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    length(dataset)
end
function eachmodality(dataset::Union{AbstractVector,Tuple})
    # @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    dataset
end
function ninstances(dataset::Union{AbstractVector,Tuple})
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    ninstances(first(dataset))
end

function instances(
    dataset::Union{AbstractVector,Tuple},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    map(modality->instances(modality, inds, return_view; kwargs...), eachmodality(dataset))
end

function concatdatasets(datasets::Union{AbstractVector,Tuple}...)
    @assert all(ismultilogiseed.(datasets)) "$(typeof.(datasets))"
    @assert allequal(nmodalities.(datasets)) "Cannot concatenate multilogiseed's of type ($(typeof.(datasets))) with mismatching " *
        "number of modalities: $(nmodalities.(datasets))"
    out = [concatdatasets([modality(dataset, i_mod) for dataset in datasets]...) for i_mod in 1:nmodalities(first(datasets))]
    if eltype(datasets) <: Tuple
        out = Tuple(out)
    end
    out
end

function displaystructure(dataset; indent_str = "", include_ninstances = true, kwargs...)
    if ismultilogiseed(dataset)
        pieces = []
        push!(pieces, "multilogiseed with $(nmodalities(dataset)) modalities ($(humansize(dataset)))")
        # push!(pieces, indent_str * "├ # modalities:\t$(nmodalities(dataset))")
        if include_ninstances
            push!(pieces, indent_str * "├ # instances:\t$(ninstances(dataset))")
        end
        # push!(pieces, indent_str * "├ modalitytype:\t$(modalitytype(dataset))")
        for (i_modality, mod) in enumerate(eachmodality(dataset))
            out = ""
            if i_modality == nmodalities(dataset)
                out *= "$(indent_str)└"
            else
                out *= "$(indent_str)├"
            end
            out *= "{$i_modality} "
            # \t\t\t$(humansize(mod))\t(worldtype: $(worldtype(mod)))"
            out *= displaystructure(mod; indent_str = indent_str * (i_modality == nmodalities(dataset) ? "  " : "│ "), include_ninstances = false, kwargs...)
            push!(pieces, out)
        end
        return join(pieces, "\n")
    elseif islogiseed(dataset)
        return "logiseed ($(humansize(dataset)))\n$(dataset)" |> x->"$(replace(x, "\n"=>"$(indent_str)\n"))\n"
    else
        return "?? dataset of type $(typeof(dataset)) ($(humansize(dataset))) ??\n$(dataset)\n" |> x->"$(replace(x, "\n"=>"$(indent_str)\n"))\n"
    end
end


# TODO explain kwargs
"""
    scalarlogiset(dataset, features; kwargs...)

Converts a dataset structure (with variables) to a logiset with scalar-valued features.
If `dataset` is not a multimodal dataset, the following methods should be defined:
TODO explain
```julia
    islogiseed(::typeof(dataset)) = true
    initlogiset(dataset, features)
    ninstances(dataset)
    nvariables(dataset)
    frame(dataset, i_instance::Integer)
    featvalue(feature::VarFeature, dataset, i_instance::Integer, w::AbstractWorld)
    vareltype(dataset, i_variable::Integer)
```

If `dataset` represents a multimodal dataset, the following methods should be defined,
while its modalities (iterated via `eachmodality`) should provide the methods above:

```julia
    ismultilogiseed(dataset)
    nmodalities(dataset)
    eachmodality(dataset)
```

See also
[`AbstractModalLogiset`](@ref),
[`VarFeature`](@ref),
[`ScalarCondition`](@ref).
"""
function scalarlogiset(
    dataset,
    features::Union{Nothing,AbstractVector} = nothing;
    #
    use_full_memoization             :: Union{Bool,Type{<:Union{AbstractOneStepMemoset,AbstractFullMemoset}}} = true,
    #
    conditions                       :: Union{Nothing,AbstractVector{<:AbstractCondition},AbstractVector{<:Union{Nothing,AbstractVector}}} = nothing,
    relations                        :: Union{Nothing,AbstractVector{<:AbstractRelation},AbstractVector{<:Union{Nothing,AbstractVector}}} = nothing,
    use_onestep_memoization          :: Union{Bool,Type{<:AbstractOneStepMemoset}} = !isnothing(conditions) && !isnothing(relations),
    onestep_precompute_globmemoset   :: Bool = (use_onestep_memoization != false),
    onestep_precompute_relmemoset    :: Bool = false,
    print_progress                   :: Bool = false,
    allow_propositional              :: Bool = false, # TODO default to true
    # featvaltype = nothing
)
    is_feature(f) = (f isa MixedCondition)
    is_nofeatures(_features) = isnothing(_features)
    is_unifeatures(_features) = (_features isa AbstractVector && all(f->is_feature(f), _features))
    is_multifeatures(_features) = (_features isa AbstractVector && all(fs->(is_nofeatures(fs) || is_unifeatures(fs)), _features))

    # @show conditions
    # @show typeof(conditions)
    # @show features
    # @show typeof(features)
    # @show typeof(dataset)
    # @show ismultilogiseed(dataset)

    @assert (is_nofeatures(features) ||
            is_unifeatures(features) ||
            is_multifeatures(features)) "Unexpected features (type: $(typeof(features))).\n" *
            "$(features)" *
            "Suspects: $(filter(f->(!is_feature(f) && !is_nofeatures(f) && !is_unifeatures(f)), features))"

    if ismultilogiseed(dataset)

        kwargs = (;
            use_full_memoization = use_full_memoization,
            use_onestep_memoization = use_onestep_memoization,
            onestep_precompute_globmemoset = onestep_precompute_globmemoset,
            onestep_precompute_relmemoset = onestep_precompute_relmemoset,
        )

        features = begin
            if is_unifeatures(features) || is_nofeatures(features)
                fill(features, nmodalities(dataset))
            elseif is_multifeatures(features)
                features
            else
                error("Cannot build multimodal scalar logiset with features " *
                    "$(features), " *
                    "$(SoleLogics.displaysyntaxvector(features)).")
            end
        end

        conditions = begin
            if conditions isa Union{Nothing,AbstractVector{<:AbstractCondition}}
                fill(conditions, nmodalities(dataset))
            elseif conditions isa AbstractVector{<:Union{Nothing,AbstractVector}}
                conditions
            else
                error("Cannot build multimodal scalar logiset with conditions " *
                    "$(SoleLogics.displaysyntaxvector(conditions)).")
            end
        end

        relations = begin
            if relations isa Union{Nothing,AbstractVector{<:AbstractRelation}}
                fill(relations, nmodalities(dataset))
            elseif relations isa AbstractVector{<:Union{Nothing,AbstractVector}}
                relations
            else
                error("Cannot build multimodal scalar logiset with relations " *
                    "$(SoleLogics.displaysyntaxvector(relations)).")
            end
        end

        if print_progress
            p = Progress(nmodalities(dataset); dt = 1, desc = "Computing multilogiset...")
        end
        return MultiLogiset([begin
                # println("Modality $(i_modality)/$(nmodalities(dataset))")
                X = scalarlogiset(
                    _dataset,
                    _features;
                    conditions = _conditions,
                    relations = _relations,
                    print_progress = false,
                    kwargs...
                )
                if print_progress
                    next!(p)
                end
                X
            end for (i_modality, (_dataset, _features, _conditions, _relations)) in
                    enumerate(zip(eachmodality(dataset), features, conditions, relations))
            ])
    end

    if allow_propositional && all(i_instance->nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))
        return PropositionalLogiset(dataset)
    end

    @assert is_nofeatures(features) || is_unifeatures(features) "Unexpected features (type: $(typeof(features))).\n" *
        "$(features)" *
        "Suspects: $(filter(f->(!is_feature(f) && !is_nofeatures(f) && !is_unifeatures(f)), features))"

    if isnothing(features)
        features = begin
            if isnothing(conditions)
                is_propositional_dataset = all(i_instance->nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))
                if is_propositional_dataset
                    [VariableValue(i_var) for i_var in 1:nvariables(dataset)]
                else
                    vcat([[VariableMax(i_var), VariableMin(i_var)] for i_var in 1:nvariables(dataset)]...)
                end
            else
                unique(feature.(conditions))
            end
        end
    else
        if isnothing(conditions)
            conditions = naturalconditions(dataset, features)
            features = unique(feature.(conditions))
            if use_onestep_memoization == false
                conditions = nothing
            end
        else
            if !all(f->f isa VarFeature, features) # or AbstractFeature
                error("Unexpected case (TODO). " *
                    "features = $(typeof(features)), conditions = $(typeof(conditions)). " *
                    "Suspects: $(filter(f->!(f isa VarFeature), features))"
                )
            end
        end
    end

    # Too bad this breaks the code
    # if !isnothing(conditions)
    #     conditions = unique(conditions)
    # end

    # TODO remove, and maybe bring back the unique on conditions...?
    # features = unique(features)

    # features_ok = filter(f->isconcretetype(SoleData.featvaltype(dataset, f)), features)
    # features_notok = filter(f->!isconcretetype(SoleData.featvaltype(dataset, f)), features)


    # if length(features_notok) > 0
    #     if all(preserveseltype, features_notok) && all(f->f isa AbstractUnivariateFeature, features_notok)
    #         @assert false "TODO"
    #         _fixfeature(f) = begin
    #             U = vareltype(dataset, i_variable(f))
    #             eval(nameof(typeof(f))){U}(f)
    #         end
    #         features_notok_fixed = [_fixfeature(f) for f in features_notok]
    #         # TODO
    #         # conditions_ok = filter(c->!(feature(c) in features_notok), conditions)
    #         # conditions_notok = filter(c->(feature(c) in features_notok), conditions)
    #         # conditions_notok_fixed = [begin
    #         #     @assert c isa ScalarMetaCondition "$(typeof(c))"
    #         #     f = feature(c)
    #         #     ScalarMetaCondition(_fixfeature(f), test_operator(c))
    #         # end for c in conditions_notok]
    #         if !is_nofeatures(features)
    #             @warn "Patching $(length(features_notok)) features using vareltype."
    #         end
    #         features = [features_ok..., features_notok_fixed...]
    #         # conditions = [conditions_ok..., conditions_notok_fixed...]
    #     else
    #         @warn "Could not infer feature value type for some of the specified features. " *
    #                 "Please specify the feature value type upon construction. Untyped " *
    #                 "features: $(SoleLogics.displaysyntaxvector(features_notok))"
    #     end
    # end
    features = UniqueVector(features)

    @assert length(features) > 0 "Unexpected error."

    # Too bad this breaks the code
    # if !isnothing(conditions)
    #     orphan_feats = filter(f->!(f in feature.(conditions)), features)

    #     if length(orphan_feats) > 0
    #         @warn "Orphan features found: $(orphan_feats)"
    #     end
    # end

    # Initialize the logiset structure
    X = initlogiset(dataset, features)

    # Load explicit features (if any)
    if any(isa.(features, ExplicitFeature))
        i_external_features = first.(filter(((i_feature,isexplicit),)->(isexplicit), collect(enumerate(isa.(features, ExplicitFeature)))))
        for i_feature in i_external_features
            feature = features[i_feature]
            featvalues!(X, feature.X, i_feature)
        end
    end

    # Load internal features
    i_features = first.(filter(((i_feature,isexplicit),)->!(isexplicit), collect(enumerate(isa.(features, ExplicitFeature)))))
    enum_features = zip(i_features, features[i_features])

    _ninstances = ninstances(dataset)

    # Compute features
    if print_progress
        p = Progress(_ninstances; dt = 1, desc = "Computing logiset...")
    end
    @inbounds Threads.@threads for i_instance in 1:_ninstances
        for w in allworlds(dataset, i_instance)
            for (i_feature,feature) in enum_features
                featval = featvalue(feature, dataset, i_instance, w)
                featvalue!(feature, X, featval, i_instance, w, i_feature)
            end
        end
        if print_progress
            next!(p)
        end
    end

    if !use_full_memoization && !use_onestep_memoization
        X
    else
        SupportedLogiset(X;
            use_full_memoization = use_full_memoization,
            use_onestep_memoization = use_onestep_memoization,
            conditions = conditions,
            relations = relations,
            onestep_precompute_globmemoset = onestep_precompute_globmemoset,
            onestep_precompute_relmemoset = onestep_precompute_relmemoset,
        )
    end
end


function naturalconditions(
    dataset,
    mixed_conditions   :: AbstractVector,
    featvaltype        :: Union{Nothing,Type} = nothing
)
    # TODO maybe? Should work
    # if ismultilogiseed(dataset)
    #     mixed_conditions = begin
    #         if mixed_conditions isa AbstractVector{<:AbstractVector}
    #             mixed_conditions
    #         else
    #             fill(mixed_conditions, nmodalities(dataset))
    #         end
    #     end

    #     return [naturalconditions(mod, mixed_conditions, featvaltype) for mod in eachmodality(dataset)]
    # end

    @assert !any(isa.(mixed_conditions, AbstractVector{<:AbstractVector})) "Unexpected mixed_conditions: $(mixed_conditions)."

    nvars = nvariables(dataset)

    @assert all(isa.(mixed_conditions, MixedCondition)) "" *
        "Unknown condition seed encountered! " *
        "$(filter(f->!isa(f, MixedCondition), mixed_conditions)), " *
        "$(typeof.(filter(f->!isa(f, MixedCondition), mixed_conditions)))"

    mixed_conditions = Vector{MixedCondition}(mixed_conditions)

    is_propositional_dataset = all(i_instance->nworlds(frame(dataset, i_instance)) == 1, 1:ninstances(dataset))

    def_test_operators = is_propositional_dataset ? [≥] : [≥, <]

    univar_condition(i_var,cond::SoleData.CanonicalConditionGeq) = ([≥],VariableMin(i_var))
    univar_condition(i_var,cond::SoleData.CanonicalConditionLeq) = ([<],VariableMax(i_var))
    univar_condition(i_var,cond::SoleData.CanonicalConditionGeqSoft) = ([≥],VariableSoftMin(i_var, cond.alpha))
    univar_condition(i_var,cond::SoleData.CanonicalConditionLeqSoft) = ([<],VariableSoftMax(i_var, cond.alpha))
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(identity)})
        return (test_ops,VariableValue(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(minimum)})
        return (test_ops,VariableMin(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},typeof(maximum)})
        return (test_ops,VariableMax(i_var))
    end
    function univar_condition(i_var,(test_ops,cond)::Tuple{<:AbstractVector{<:TestOperator},Base.Callable})
        if isnothing(featvaltype)
            featvaltype = SoleData.vareltype(dataset, i_var)
        end
        V = featvaltype
        if !isconcretetype(V)
            @warn "Building UnivariateFeature with non-concrete feature type: $(V)."
                "Please provide `featvaltype` parameter to naturalconditions."
        end
        # f = function (x) return V(cond(x)) end # breaks because it does not create a closure.
        f = cond
        return (test_ops,UnivariateFeature{V}(i_var, f))
    end
    univar_condition(i_var,::Any) = throw_n_log("Unknown mixed_feature type: $(cond), $(typeof(cond))")


    # readymade conditions
    unpackcondition(cond::ScalarMetaCondition) = [cond]
    unpackcondition(feature::AbstractFeature) = [ScalarMetaCondition(feature, test_op) for test_op in def_test_operators]
    unpackcondition(cond::Tuple{TestOperator,AbstractFeature}) = [ScalarMetaCondition(cond[2], cond[1])]

    # single-variable conditions
    unpackcondition(cond::Any) = cond
    # unpackcondition(cond::CanonicalCondition) = cond
    unpackcondition(cond::Base.Callable) = (def_test_operators, cond)
    function unpackcondition(cond::Tuple{Base.Callable,Integer})
        return univar_condition(cond[2], (def_test_operators, cond[1]))
    end
    unpackcondition(cond::Tuple{TestOperator,Base.Callable}) = ([cond[1]], cond[2])

    metaconditions = ScalarMetaCondition[]

    mixed_conditions = unpackcondition.(mixed_conditions)

    readymade_conditions          = filter(x->
        isa(x, Vector{<:ScalarMetaCondition}),
        mixed_conditions,
    )
    variable_specific_conditions = filter(x->
        isa(x, CanonicalCondition) ||
        # isa(x, Tuple{<:AbstractVector{<:TestOperator},Base.Callable}) ||
        (isa(x, Tuple{AbstractVector,Base.Callable}) && !isa(x, Tuple{AbstractVector,AbstractFeature})),
        mixed_conditions,
    )

    @assert length(readymade_conditions) + length(variable_specific_conditions) == length(mixed_conditions) "" *
        "Unexpected mixed_conditions. " *
        "$(mixed_conditions). " *
        "$(filter(x->(! (x in readymade_conditions) && ! (x in variable_specific_conditions)), mixed_conditions)). " *
        "$(length(readymade_conditions)) + $(length(variable_specific_conditions)) == $(length(mixed_conditions))."

    for cond in readymade_conditions
        append!(metaconditions, cond)
    end

    for i_var in 1:nvars
        for (test_ops,feature) in map((cond)->univar_condition(Symbol(names(dataset)[i_var]),cond),variable_specific_conditions)
            for test_op in test_ops
                cond = ScalarMetaCondition(feature, test_op)
                push!(metaconditions, cond)
            end
        end
    end

    metaconditions
end

# TODO examples
"""
    naturalgrouping(
        X::AbstractDataFrame;
        allow_variable_drop = false,
    )::AbstractVector{<:AbstractVector{<:Symbol}}

Return variables grouped by their logical nature;
the nature of a variable is automatically derived
from its type (e.g., Real, Vector{<:Real} or Matrix{<:Real}) and frame.
All instances must have the same frame (e.g., channel size/number of worlds).
"""
function naturalgrouping(
    X::AbstractDataFrame;
    allow_variable_drop = false,
    # allow_nonuniform_variable_types = false,
    # allow_nonuniform_variables = false,
) #::AbstractVector{<:AbstractVector{<:Symbol}}

    coltypes = eltype.(eachcol(X))

    function _frame(datacolumn, i_instance)
        if hasmethod(frame, (typeof(X), typeof(datacolumn), Integer))
            frame(X, datacolumn, i_instance)
        else
            missing
        end
    end

    # Check that columns with same dimensionality have same eltype's.
    for T in [Real, Vector, Matrix]
        these_coltypes = filter((t)->(t<:T), coltypes)
        @assert all([eltype(t) <: Real for t in these_coltypes]) "$(these_coltypes). Cannot " *
          "apply this algorithm on variables types with non-Real " *
          "eltype's: $(filter((t)->(!(eltype(t) <: Real)), these_coltypes))."
        @assert length(unique(these_coltypes)) <= 1 "$(these_coltypes). Cannot " *
          "apply this algorithm on dataset with non-uniform types for variables " *
          "with eltype = $(T). Please, convert all values to $(promote_type(these_coltypes...))."
    end

    columnnames = names(X)
    percol_framess = [unique(map((i_instance)->(_frame(X[:,col], i_instance)), 1:ninstances(X))) for col in columnnames]

    # Must have common frame across instances
    _uniform_columns = (length.(percol_framess) .== 1)
    _framed_columns = (((cs)->all((!).(ismissing.(cs)))).(percol_framess))

    __nonuniform_cols = columnnames[(!).(_uniform_columns)]
    if length(__nonuniform_cols) > 0
        if allow_variable_drop
            @warn "Dropping columns due to non-uniform frame across instances: $(join(__nonuniform_cols, ", "))..."
        else
            error("Non-uniform frame across instances for columns $(join(__nonuniform_cols, ", "))")
        end
    end
    __uniform_nonframed_cols = columnnames[_uniform_columns .&& (!).(_framed_columns)]
    if length(__uniform_nonframed_cols) > 0
        if allow_variable_drop
            @warn "Dropping columns due to unspecified frame: $(join(__uniform_nonframed_cols, ", "))..."
        else
            error("Could not derive frame for columns $(join(__uniform_nonframed_cols, ", "))")
        end
    end

    _good_columns = _uniform_columns .&& _framed_columns

    if length(_good_columns) == 0
        error("Could not find any suitable variables in DataFrame.")
    end

    percol_framess = percol_framess[_good_columns]
    columnnames = Symbol.(columnnames[_good_columns])
    percol_frames = getindex.(percol_framess, 1)

    var_grouping = begin
        unique_frames = sort(unique(percol_frames); lt = (x,y)->begin
            if hasmethod(dimensionality, (typeof(x),)) && hasmethod(dimensionality, (typeof(y),))
                if dimensionality(x) == dimensionality(y)
                    isless(MultiData.channelsize(x), MultiData.channelsize(y))
                else
                    isless(dimensionality(x), dimensionality(y))
                end
            elseif hasmethod(dimensionality, (typeof(x),))
                true
            else
                false
            end
        end)

        percol_modality = [findfirst((ucs)->(ucs==cs), unique_frames) for cs in percol_frames]

        var_grouping = Dict([modality => [] for modality in unique(percol_modality)])
        for (modality, col) in zip(percol_modality, columnnames)
            push!(var_grouping[modality], col)
        end
        [var_grouping[modality] for modality in unique(percol_modality)]
    end

    var_grouping
end
