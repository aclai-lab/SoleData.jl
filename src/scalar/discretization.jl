
macro showlc(list, c)
    return esc(quote
        infolist = (length($list) == 0 ?
                        "EMPTY" :
                        "len: $(length($list))"
                    )
        printstyled($(string(list)),  " | $infolist \n", bold=true, color=$c)
        for (ind, element) in enumerate($list)
            printstyled(ind,") ",element, "\n", color=$c)
        end
    end)

end

nncols(M::Matrix) = size(M)[1]

function entropy_normalized2(D)

     rows = eachrow(D)

     return [ (pr = pr[ pr .!= 0 ]; -sum( pr .* log.(2, pr)))
	for pr in rows
     ]
end

# Normalize X so it sums to 1.0 over the 'axis'
function _normalize(X; axis::Int64)

	scale = sum(X, dims=axis)
	scale[ scale .== 0 ] .= 1

	return X ./ scale
end

# Compute the entropy of distributions in D (one per each row)
function _entropy1(D)
	D = _normalize(D, axis=2)
	return entropy_normalized2(D)[1]
end

function _entropy2(D)
	D = _normalize(D, axis=2)
	return entropy_normalized2(D)
end

function entropy_cut_sorted(CS)

	S1Dist = cumsum(CS, dims=1)[1:(end-1), :]
	S2Dist = cumsum(CS[end:-1:1, :], dims=1)[(end-1):-1:1, :]

	ES1 = _entropy2(S1Dist)
	ES2 = _entropy2(S2Dist)


# number of cases in S1[i] and S2[i]
	S1_count = sum(S1Dist, dims=2)
	S2_count = sum(S2Dist, dims=2)

	# number of all cases
	S_count = sum(CS)

	ES1w = ES1 .* S1_count ./ S_count
	ES2w = ES2 .* S2_count ./ S_count

	# E(A, T; S) Class information entropy of the partition S
	E = ES1w + ES2w

	return E, ES1, ES2

end

function contingency(
	C::Vector, 	# Column of the dataset
	y::Vector
)
	vals  = sort(unique(C))
	classes = unique(y)

	# Create empty dict for classes
	counts_ = Array{Float64}(undef, 0, length(classes))

	for val ∈ vals
		valus_y  = y[ C .== val ]
		start_d = Dict(	map(class -> (class => 0),  classes))
		addcounts!(start_d, valus_y, alg = :auto)
		counts_ = vcat(counts_, collect(values(start_d))')
	end
	return vals, counts_
end


function _entropy_discretize_sorted(C)

	E, ES1, ES2 = entropy_cut_sorted(C)

	length(E) == 0 && return []

	cut_index = argmin(E[:]) + 1

	# Distribution of the classes in S1, S2 and S

    @showlc eachrow(C[ 1:cut_index,       :]) :green
	@showlc eachrow(C[ (cut_index+1):end, :]) :green

    S1_c = sum( C[ 1:cut_index,       :], dims=1)
	S2_c = sum( C[ (cut_index+1):end, :], dims=1)
    S_c = S1_c + S2_c


	ES = _entropy1(sum(C, dims=1))
	ES1 = ES1[cut_index-1]
	ES2 = ES2[cut_index-1]
	# Information gain of the best split

	Gain = ES - E[cut_index-1]
	# # Number of different classes in S, S1 and S2
	k  = sum(S_c .> 0)
	k1 = sum(S1_c .> 0)
	k2 = sum(S2_c .> 0)


	# asserty k > 0
	delta = log2(3^k - 2) - (k * ES - k1 * ES1 - k2 * ES2)
	N = sum(S_c)

	#COMMENT
	println("========================================")
	# @show C
	# @show E
	println("________________________________________")
    println("S1_c  = $(S2_c)")
	println("S2_c  = $(S2_c)")
	println("S_c  = $(S2_c)")
	println("________________________________________")

	println("cut_index  = $(cut_index)")
	println("sum(C, dims=1) = $(sum(C, dims=1))")
	println("\tES = $(ES)")
	println("\t\tES1 = $(ES1)")
	println("\t\tES2 = $(ES2)")
	println("k  = $(k)")
	println("k1 = $(k1)")
	println("k2 = $(k2)")
	println("delta = $(delta)")
	println("length(C) = $(nncols(C))")
	println("N = $(N)")
	println("\t$(Gain) > $((log2(N - 1)/N) + (delta/N))")
	println("========================================")
	readline()

	if N > 1 && Gain > ( (log2(N - 1)/N) + (delta/N) )

		# Accept the cut point and recursively split the subsets.
		left, right = [], []
		if k1 > 1 && cut_index > 1
			# println("-- LEFT -- ")
			left = _entropy_discretize_sorted(C[1:(cut_index-1), :])
		end

		if k2 > 1 && cut_index < nncols(C) - 1
			# println("-- RIGTH -- ")
			right = _entropy_discretize_sorted(C[cut_index:end, :])
		end
		#COMMENT
		# println("cut_index = $(cut_index)")
		# println("right = $(right)")
		# println("left = $(left)")
		# println("ret = $(union(left, [cut_index], [i + cut_index for i in right]))")
		# println("===========================")

		return union(left, [cut_index], [(i + cut_index - 1) for i in right])
	# elseif force
	# 	return [cut_index]
	else
		return []
	end

end

function discretize(
	X::AbstractVector,
	y::AbstractVector
)
	vals, counts_ = contingency(X,y)
	cut_ind = _entropy_discretize_sorted(counts_)
	return [vals[ind] for ind in cut_ind]
end
