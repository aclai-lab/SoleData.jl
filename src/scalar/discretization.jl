using StatsBase: addcounts!
############################################################################################
######################### Fayyad Discretization Algorithm ##################################
# Reference: Multi-interval discretization of continuous-valued attributes for classification learning, Fayyad, 1993
############################################################################################

nncols(M::Matrix) = size(M)[1]

function entropy_normalized2(D)
    rows = eachrow(D)

    return [(pr = pr[pr .!= 0]; -sum(pr .* log.(2, pr)))
            for pr in rows]
end

# Normalize threshold_domain so it sums to 1.0 over the 'axis'
function _normalize(threshold_domain; axis::Int64)
    scale = sum(threshold_domain, dims = axis)
    scale[scale .== 0] .= 1

    return threshold_domain ./ scale
end

# Compute the entropy of distributions in D (one per each row)
function _entropy1(D)
    D = _normalize(D, axis = 2)
    return entropy_normalized2(D)[1]
end

function _entropy2(D)
    D = _normalize(D, axis = 2)
    return entropy_normalized2(D)
end

function entropy_cut_sorted(CS)
    S1Dist = cumsum(CS, dims = 1)[1:(end - 1), :]
    S2Dist = cumsum(CS[end:-1:1, :], dims = 1)[(end - 1):-1:1, :]

    ES1 = _entropy2(S1Dist)
    ES2 = _entropy2(S2Dist)

    # number of cases in S1[i] and S2[i]
    S1_count = sum(S1Dist, dims = 2)
    S2_count = sum(S2Dist, dims = 2)

    # number of all cases
    S_count = sum(CS)

    ES1w = ES1 .* S1_count ./ S_count
    ES2w = ES2 .* S2_count ./ S_count

    # E(A, T; S) Class information entropy of the partition S
    E = ES1w + ES2w

    return E, ES1, ES2
end

function contingency(C::AbstractVector, y::AbstractVector)
	vals  = sort(unique(C))
	classes = unique(y)

    counts_ = Array{Float64}(undef, 0, length(classes))

    for val in vals
        valus_y = y[C .== val]
        start_d = Dict(map(class -> (class => 0), classes))
        addcounts!(start_d, valus_y, alg = :auto)
        counts_ = vcat(counts_, collect(values(start_d))')
    end
    return vals, counts_
end

function _entropy_discretize_sorted(
	C;
	force = false
)
    E, ES1, ES2 = entropy_cut_sorted(C)

    length(E) == 0 && return []

	cut_index = argmin(E[:])

    S1_c = sum(C[1:cut_index, :], dims = 1)
    S2_c = sum(C[(cut_index + 1):end, :], dims = 1)
    S_c = S1_c + S2_c

    ES = _entropy1(sum(C, dims = 1))
    ES1 = ES1[cut_index]
    ES2 = ES2[cut_index]

    # Information gain of the best split
    Gain = ES - E[cut_index]

    # # Number of different classes in S, S1 and S2
    k = sum(S_c .> 0)
    k1 = sum(S1_c .> 0)
    k2 = sum(S2_c .> 0)

    @assert k < 80 "Too many classes"

    # asserty k > 0
    delta = log2(3^k - 2) - (k * ES - k1 * ES1 - k2 * ES2)
    N = sum(S_c)

	if N > 1 && Gain > ( (log2(N - 1)/N) + (delta/N) )
		left, right = [], []
		if k1 > 1 && cut_index > 1
			left = _entropy_discretize_sorted(C[1:(cut_index), :])
		end
		if k2 > 1 && cut_index < nncols(C) - 1
			right = _entropy_discretize_sorted(C[cut_index+1:end, :])
		end
		return union(left, [cut_index + 1], [(i + cut_index) for i in right])
	elseif force
		return [cut_index + 1]
	else
		return []
	end
end

function discretize(
	threshold_domain::AbstractVector,
	y::AbstractVector
)
	vals, counts_ = contingency(threshold_domain,y)
	cut_ind = _entropy_discretize_sorted(counts_, force=true)
	return [vals[ind] for ind in cut_ind]
end
