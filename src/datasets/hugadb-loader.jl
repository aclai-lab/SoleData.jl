HUGADB_VARIABLENAMES = ["acc_rf_x","acc_rf_y","acc_rf_z",
    "gyro_rf_x","gyro_rf_y","gyro_rf_z",
    "acc_rs_x","acc_rs_y","acc_rs_z",
    "gyro_rs_x","gyro_rs_y","gyro_rs_z",
    "acc_rt_x","acc_rt_y","acc_rt_z",
    "gyro_rt_x","gyro_rt_y","gyro_rt_z",
    "acc_lf_x","acc_lf_y","acc_lf_z",
    "gyro_lf_x","gyro_lf_y","gyro_lf_z",
    "acc_ls_x","acc_ls_y","acc_ls_z",
    "gyro_ls_x","gyro_ls_y","gyro_ls_z",
    "acc_lt_x","acc_lt_y","acc_lt_z",
    "gyro_lt_x","gyro_lt_y","gyro_lt_z",
    "EMG_r","EMG_l","act",
]

# activity strings (labels) to ids as in the table at https://github.com/romanchereshnev/HuGaDB
_activity2id = x -> findfirst(activity -> x == activity, [
    "walking", "running", "going_up", "going_down", "sitting", "sitting_down",
    "standing_up", "standing", "bicycling", "elevator_up", "elevator_down",
    "sitting_car"
])

"""
    function load_hugadb(dirpath::S, filename::S) where {S<:AbstractString}

Loader for a single instance of `HuGaDB` dataset, available [here](https://github.com/romanchereshnev/HuGaDB).

# Arguments
- `dirpath::S`: the directory in which all the .txt files are stored;
- `filename::S`: the specific filename associated with the instance, such as
    HuGaDB_v2_various_01_00.txt.

# Keyword Arguments
- `variablenames::Vector{S}=["x_accelometer_right_foot", "y_accelerometer_right_foot", ...]`:
    the names of the columns.
"""
function load_hugadb(
    dirpath::S,
    filename::S;
    variablenames::Vector{S}=HUGADB_VARIABLENAMES
) where {S<:AbstractString}
    filepath = joinpath(dirpath, filename)

    # e.g. open("test/data/HuGaDB/HuGaDB_v2_various_01_00.txt", "r")
    f = open(filepath, "r")

    # get the activities recorded for the performer specified in `filename`
    activities = split(readline(f), " ")[1:end-1]
    activities[1] = activities[1][11:end] # remove the initial "#Activity\t"


    activity_ids = [_activity2id(activity) for activity in activities]

    # ignore #ActivityID array (we only keep the string version instead of integer IDs)
    readline(f)

    # ignore #Date row
    readline(f)

    # ignore the variable names, as we already explicited them in `variablenames`
    readline(f)

    _substr2float = x -> parse(Float64, x)
    lines = [_substr2float.(split(line, "\t")) for line in eachline(f)]

    close(f)

    X = DataFrame([
        # get the i-th element from each line, and concatenate them together
        [[line[i] for line in lines]]
        for i in 1:length(variablenames)
    ], variablenames)

    # variablenames is returned to help the user, for example to let him know our default
    # values if he did not provide any.
    return X, (activities, activity_ids), variablenames
end

# load multiple HuGaDB instances in one DataFrame
"""
    function load_hugadb(
        dirpath::S,
        filenames::Vector{S};
        kwargs...
    ) where {S<:AbstractString}

Loader for multiple instances of `HuGaDB` dataset, each of which is identified by a file
name (in `filenames` vector) inside the directory `dirpath`.

!!! note
    The main purpose of this dispatch is to be picky about which instances to load and
    which to discard, since some HuGaDB recordings are corrupted.
    More info on [the official GitHub page](https://github.com/romanchereshnev/HuGaDB).

See also the dispatch of this method which only considers one filename.
"""
function load_hugadb(
    dirpath::S,
    filenames::Vector{S};
    kwargs...
) where {S<:AbstractString}
    # leverage the first instance to get, once for all, the common outputs such as
    # the list of activities (as pairs string/id pairs) and the names of each column.
    X, (activity_strings, activity_ids), variablenames = load_hugadb(
        dirpath, filenames[1], kwargs...)

    # return the concatenation of each DataFrame obtained by a `load_hugadb` call
    return vcat([X, [
            load_hugadb(dirpath, filename; kwargs...) |> first
            for filename in filenames[2:end]
        ]...]...), (activity_strings, activity_ids), variablenames
end

# in each instance, isolate the recorded part dedicated to `id` movement;
# if no such part exists, discard the instance.
# The survivor tracks are trimmed to have the same length.
"""
    function filter_hugadb(X::DataFrame, id; labelcolumn::Integer=39)

Utility function related to `HuGaDB` dataset, called `X`.

Consider the recordings of each performer (i.e., every instance) and isolate the data
related to one specific movement id.

# Arguments
- `X::DataFrame`: the HuGaDB dataset;
- `id`: any kind of data contained in `labelcolumn` (probably an integer or a string), to
    discriminate between different movements.

# Keyword Arguments
- `labelcolumn::Integer=39`: by default, movement ids are stored in this column.
"""
function filter_hugadb(X::DataFrame, id; labelcolumn::Integer=39)
    nvariables = X |> size |> last

    # pick only the instances for which an `id` type of movement is recorded
    _X = [
        let indices = findall(x -> x == id, X[instance, labelcolumn])
        isempty(indices) ? nothing :
        DataFrame([
                [X[instance, variable][indices]]
                for variable in 1:nvariables
            ], variablenames)
        end
        for instance in 1:(X |> size |> first)
    ] |> x -> filter(!isnothing, x)

    # concatenate all the picked instances in an unique DataFrame
    _Xfiltered = vcat(_X...)

    # we want to trim every recording to have the same length across instances;
    # since, when selecting an instance, each column of the latter has the same length,
    # we arbitrarily choose to compute the minimum length starting from the first column.
    minimum_length = minimum(length.(_Xfiltered[:,1]))
    for instance in 1:(_Xfiltered |> size |> first)
        for variable in 1:nvariables
            _Xfiltered[instance,variable] = _Xfiltered[instance,variable][1:minimum_length]
        end
    end

    return _Xfiltered
end
