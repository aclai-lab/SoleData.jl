import SoleLogics: check
using SoleLogics: normalize
using SoleLogics: AnyWorld
using SoleLogics: value
using SoleLogics: CheckAlgorithm

function check(
    ::CheckAlgorithm,
    φ::Atom{<:AbstractCondition},
    i::SoleLogics.LogicalInstance{<:AbstractLogiset},
    args...;
    kwargs...
)
    X, i_instance = SoleLogics.splat(i)
    cond = SoleLogics.value(φ)
    return checkcondition(cond, X, i_instance, args...; kwargs...)
end

function check(
    ::CheckAlgorithm,
    φ::Atom{<:AbstractCondition},
    i::SoleLogics.LogicalInstance{<:AbstractModalLogiset{W,<:U}},
    w::Union{Nothing,AnyWorld,<:AbstractWorld} = nothing,
    args...;
    use_memo = nothing,
    kwargs...
) where {W<:AbstractWorld,U}
    X, i_instance = SoleLogics.splat(i)
    cond = SoleLogics.value(φ)
    return checkcondition(cond, X, i_instance, w, args...)
end

"""
    check(
        ::CheckAlgorithm,
        φ::SoleLogics.SyntaxTree,
        i::SoleLogics.LogicalInstance{<:AbstractModalLogiset{W,<:U}},
        w::Union{Nothing,AnyWorld,<:AbstractWorld} = nothing;
        kwargs...
    )::Bool

Check whether a formula `φ` holds for a given instance `i_instance` of a logiset `X`, on a world `w`.
Note that the world can be elided for grounded formulas (see [`isgrounded`](@ref)).

This implementation recursively evaluates the subformulas of `φ` and use memoization to store the results using Emerson-Clarke algorithm.
The memoization structure is either the one stored in `X` itself (if `X` supports memoization) or a structure passed as the `use_memo` argument.
If `X` supports onestep memoization, then it will be used for specific diamond formulas, up to an height equal to a keyword argument `memo_max_height`.

# Arguments
- `φ::SoleLogics.SyntaxTree`: the formula to check.
- `i::SoleLogics.LogicalInstance{<:AbstractModalLogiset{W,<:U}}`: the instance of the logiset to check in.
- `w::Union{Nothing,AnyWorld,<:AbstractWorld} = nothing`: the world to check in. If `nothing`, the method checks in all worlds of the instance.

# Keyword arguments
- `use_memo::Union{Nothing,AbstractMemoset{<:AbstractWorld},AbstractVector{<:AbstractDict{<:FT,<:AbstractWorlds}}} = nothing`: the memoization structure to use. If `nothing`, the method uses the one stored in `X` if `X` supports memoization. If `AbstractMemoset`, the method uses the `i_instance`-th element of the memoization structure. If `AbstractVector`, the method uses the `i_instance`-th element of the vector.
- `perform_normalization::Bool = true`: whether to normalize the formula before checking it.
- `memo_max_height::Union{Nothing,Int} = nothing`: the maximum height up to which onestep memoization should be used. If `nothing`, the method does not use onestep memoization.
- `onestep_memoset_is_complete = false`: whether the onestep memoization structure is complete (i.e. it contains all possible values of the metaconditions in the structure).

"""
function check(
    ::CheckAlgorithm, 
    φ::SoleLogics.SyntaxBranch,
    i::SoleLogics.LogicalInstance{<:AbstractModalLogiset{W,<:U}},
    w::Union{Nothing,AnyWorld,<:AbstractWorld} = nothing;
    use_memo::Union{Nothing,AbstractMemoset{<:AbstractWorld},AbstractVector{<:AbstractDict{<:FT,<:AbstractWorlds}}} = nothing,
    perform_normalization::Bool = true,
    memo_max_height::Union{Nothing,Int} = nothing,
    onestep_memoset_is_complete = false,
) where {W<:AbstractWorld,U,FT<:SoleLogics.Formula}

    X, i_instance = SoleLogics.splat(i)

    if isnothing(w)
        if nworlds(frame(X, i_instance)) == 1
            w = first(allworlds(frame(X, i_instance)))
        end
    end
    @assert SoleLogics.isgrounded(φ) || !isnothing(w) "Please, specify a world in order " *
        "to check non-grounded formula: $(syntaxstring(φ))."

    setformula(memo_structure::AbstractDict{<:Formula}, φ::Formula, val) = memo_structure[SoleLogics.tree(φ)] = val
    readformula(memo_structure::AbstractDict{<:Formula}, φ::Formula) = memo_structure[SoleLogics.tree(φ)]
    hasformula(memo_structure::AbstractDict{<:Formula}, φ::Formula) = haskey(memo_structure, SoleLogics.tree(φ))

    setformula(memo_structure::AbstractMemoset, φ::Formula, val) = Base.setindex!(memo_structure, i_instance, SoleLogics.tree(φ), val)
    readformula(memo_structure::AbstractMemoset, φ::Formula) = Base.getindex(memo_structure, i_instance, SoleLogics.tree(φ))
    hasformula(memo_structure::AbstractMemoset, φ::Formula) = haskey(memo_structure, i_instance, SoleLogics.tree(φ))

    onestep_memoset = begin
        if hassupports(X) && supporttypes(X) <: Tuple{<:AbstractOneStepMemoset,<:AbstractFullMemoset}
            supports(X)[1]
        else
            nothing
        end
    end

    if perform_normalization
        # Only allow flippings when no onestep is used.
        φ = normalize(φ; profile = :modelchecking, allow_atom_flipping = isnothing(onestep_memoset))
    end

    X, memo_structure = begin
        if hassupports(X) && usesfullmemo(X)
            if !isnothing(use_memo)
                @warn "Dataset of type $(typeof(X)) uses full memoization, " *
                    "but a memoization structure was provided to check(...)."
            end
            base(X), fullmemo(X)
        elseif isnothing(use_memo)
            X, ThreadSafeDict{SyntaxTree,Worlds{W}}()
        elseif use_memo isa AbstractMemoset
            X, use_memo[i_instance]
        else
            X, use_memo[i_instance]
        end
    end

    if !isnothing(memo_max_height)
        forget_list = Vector{SoleLogics.SyntaxTree}()
    end

    fr = frame(X, i_instance)

    # TODO try lazily
    (_f, _c) = filter, collect
    # (_f, _c) = Iterators.filter, identity

    if !hasformula(memo_structure, φ)
        for ψ in unique(SoleLogics.subformulas(φ))
            if !isnothing(memo_max_height) && height(ψ) > memo_max_height
                push!(forget_list, ψ)
            end

            if !hasformula(memo_structure, ψ)
                tok = token(ψ)

                worldset = begin
                    if !isnothing(onestep_memoset) && SoleLogics.height(ψ) == 1 && tok isa SoleLogics.AbstractRelationalConnective &&
                            ((SoleLogics.relation(tok) == globalrel && nworlds(fr) != 1) || !SoleLogics.isgrounding(SoleLogics.relation(tok))) &&
                            SoleLogics.ismodal(tok) && SoleLogics.isunary(tok) && SoleLogics.isdiamond(tok) &&
                            token(first(children(ψ))) isa Atom &&
                            # Note: metacond with same aggregator also works. TODO maybe use Conditions with aggregators inside and look those up.
                            (onestep_memoset_is_complete || (metacond(SoleLogics.value(token(first(children(ψ))))) in metaconditions(onestep_memoset))) &&
                            true
                        # println("ONESTEP!")
                        # println(syntaxstring(ψ))
                        condition = SoleLogics.value(token(first(children(ψ))))
                        _metacond = metacond(condition)
                        _rel = SoleLogics.relation(tok)
                        _feature = feature(condition)
                        _featchannel = featchannel(X, i_instance, _feature)
                        _f(world->begin
                            gamma = featchannel_onestep_aggregation(X, onestep_memoset, _featchannel, i_instance, world, _rel, _metacond)
                            apply_test_operator(test_operator(_metacond), gamma, threshold(condition))
                        end, _c(allworlds(fr)))
                    elseif tok isa Connective
                        _c(SoleLogics.collateworlds(fr, tok, map(f->readformula(memo_structure, f), children(ψ))))
                    elseif tok isa SyntaxLeaf
                        # TODO write check(tok, X, i_instance, _w) and use it here instead of checkcondition.
                        condition = SoleLogics.value(tok)
                        _f(_w->checkcondition(condition, X, i_instance, _w), _c(allworlds(fr)))
                    else
                        error("Unexpected token encountered in check: $(typeof(tok))")
                    end
                end
                setformula(memo_structure, ψ, Worlds{W}(worldset))
            end
            # @show syntaxstring(ψ), readformula(memo_structure, ψ)
        end
    end

    if !isnothing(memo_max_height)
        for ψ in forget_list
            delete!(memo_structure, ψ)
        end
    end

    ret = begin
        if isnothing(w) || w isa AnyWorld
            length(readformula(memo_structure, φ)) > 0
        else
            w in readformula(memo_structure, φ)
        end
    end

    return ret
end

"""
    check(
        ::CheckAlgorithm,
        φ::Truth,
        i::LogicalInstance,
        args...;
        kwargs...
    )::Bool

Check whether a `Truth` formula holds for a given instance.

Note: This method provides a specialized implementation for `Truth` and `BooleanTruth` 
types from SoleLogics. Since these types inherit from the `Formula` supertype defined 
in SoleLogics, they require their own method definition here rather than falling back 
to the `Formula` method.
"""
function check(
    ::CheckAlgorithm,
    φ::Truth,
    i::LogicalInstance,
    args...;
    kwargs...
)
    return istop(interpret(φ, i, args...; kwargs...))
end
