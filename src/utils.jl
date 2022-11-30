using Logging
using Random

"""
Log overview info
"""
const LogOverview = LogLevel(-500)
"""
Log debug info
"""
const LogDebug = LogLevel(-1000)
"""
Log detailed debug info
"""
const LogDetail = LogLevel(-1500)

"""
    throw_n_log(str::AbstractString, err_type = ErrorException)
Log string `str` with `@error` and `throw` error of type `err_type`
"""
function throw_n_log(str::AbstractString, err_type = ErrorException)
    @error str
    throw(err_type(str))
end

"""
    nat_sort(x, y)
"Little than" function implementing natural sort.
It is to be used with Base.Sort functions as in `sort(..., lt=nat_sort)`
"""
function nat_sort(x, y)
    # https://titanwolf.org/Network/Articles/Article?AID=969b78b2-141a-43ef-9391-7c55b3c513c7
    splitbynum(x) = split(x, r"(?<=\D)(?=\d)|(?<=\d)(?=\D)")
    numstringtonum(arr) = [(n = tryparse(Float32, e)) != nothing ? n : e for e in arr]
    
    xarr = numstringtonum(splitbynum(string(x)))
    yarr = numstringtonum(splitbynum(string(y)))
    for i in 1:min(length(xarr), length(yarr))
        if typeof(xarr[i]) != typeof(yarr[i])
            a = string(xarr[i]); b = string(yarr[i])
        else
             a = xarr[i]; b = yarr[i]
        end
        if a == b
            continue
        else
            return a < b
        end
    end
    return length(xarr) < length(yarr)
end

############################################################################################
############################################################################################
############################################################################################

"""
Spawns an `rng` seeded using a number peeled from another `rng`.
Useful for reproducibility.
"""
spawn_rng(rng::Random.AbstractRNG) = Random.MersenneTwister(abs(rand(rng, Int)))
