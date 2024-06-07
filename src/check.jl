using SoleLogics: AnyWorld

# TODO docstring
function check(
    φ::SoleLogics.SyntaxTree,
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
        if X isa SupportedLogiset && supporttypes(X) <: Tuple{<:AbstractOneStepMemoset,<:AbstractFullMemoset}
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
        if X isa SupportedLogiset && usesfullmemo(X)
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
