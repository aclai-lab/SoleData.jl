
using SoleLogics: SyntaxTree
using SoleLogics
using SoleData

"""
    @scalarformula expr

Parse a logical formula on scalar conditions, such as `V1 > 10`.
Note that logical operators take precedence over comparison operators, so
it is often the case that
expressions such as `V1 > 10` must be wrapped in parentheses.

# Examples
```julia-repl
julia> φ = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 >= 2))
SyntaxBranch: (V1 > 10 ∧ V2 < 0 ∧ V2 < 0 ∧ V2 ≤ 0) ∨ (V1 ≤ 0 ∧ V1 ≤ 3 ∧ V2 ≥ 2)
```

See also [`parseformula`](@ref), [`syntaxstring`](@ref).
"""
macro scalarformula(expr)
    # @show expr

    function _parse_syntaxtree(expr)
        # @show expr
        if expr isa Symbol || expr isa Number
            # Leaf nodes (variables or constants)
            # @show "LEAF"
            return expr
        elseif expr.head == :call
            # @show ":CALL"
            # Logical operators or comparisons
            op = expr.args[1]
            # @show op
            if op in [:(<), :(<=), :(>), :(>=), :(≥), :(≤), :(==), :(!=)]
                # @show expr.args[2], expr.args[3]
                @assert expr.args[2] isa Symbol "Cannot parse feature $(expr.args[2])."
                feat = parsefeature(VarFeature, string(expr.args[2]))
                return :(Atom(ScalarCondition($feat, $op, $(expr.args[3]))))
            else
                # @show op
                args = [_parse_syntaxtree(arg) for arg in expr.args[2:end]]
                return Expr(:call, SyntaxTree, op, args...)
            end
        elseif expr.head in [:||, :&&, :!]
            # @show ":||/:&&"
            op = (
                if expr.head == :||
                    (∨)
                elseif expr.head == :&&
                    (∧)
                else
                    (¬)
                end
            )
            args = [_parse_syntaxtree(arg) for arg in expr.args]
            return Expr(:call, SyntaxTree, op, args...)
        else
            throw(
                ArgumentError(
                    "Unsupported expression type: $expr (head: $(expr.head), args: $(expr.args))",
                ),
            )
        end
    end

    parsed_tree = _parse_syntaxtree(expr)
    return esc(parsed_tree)
end
