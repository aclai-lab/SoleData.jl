struct HuGaDBLoader <: AbstractLoaderDataset
    name::String
    url::String

    # non-corrupted files, suitable to perform an experiment on Walk and Running classes;
    # see https://github.com/romanchereshnev/HuGaDB
    expfiles::Vector{String}

    # column names
    variablenames::Vector{String}

    # lambda function to convert each variable name to a specific ID
    activity2id::Function

    function HuGaDBLoader()
        new(
            "hugadb",
            "",

            # expfiles
            [
                "HuGaDB_v2_various_02_00.txt",
                "HuGaDB_v2_various_02_01.txt",
                "HuGaDB_v2_various_02_02.txt",
                "HuGaDB_v2_various_02_03.txt",
                "HuGaDB_v2_various_02_04.txt",
                "HuGaDB_v2_various_02_05.txt",
                "HuGaDB_v2_various_02_06.txt",
                "HuGaDB_v2_various_06_00.txt",
                "HuGaDB_v2_various_06_01.txt",
                "HuGaDB_v2_various_06_02.txt",
                "HuGaDB_v2_various_06_03.txt",
                "HuGaDB_v2_various_06_04.txt",
                "HuGaDB_v2_various_06_05.txt",
                "HuGaDB_v2_various_06_06.txt",
                "HuGaDB_v2_various_06_07.txt",
                "HuGaDB_v2_various_06_08.txt",
                "HuGaDB_v2_various_06_09.txt",
                "HuGaDB_v2_various_06_10.txt",
                "HuGaDB_v2_various_06_11.txt",
                "HuGaDB_v2_various_06_12.txt",
                "HuGaDB_v2_various_06_13.txt",
                "HuGaDB_v2_various_06_14.txt",
                "HuGaDB_v2_various_06_15.txt",
                "HuGaDB_v2_various_06_16.txt",
                "HuGaDB_v2_various_06_17.txt",
                "HuGaDB_v2_various_06_18.txt",
                "HuGaDB_v2_various_06_19.txt",
                "HuGaDB_v2_various_06_20.txt",
                "HuGaDB_v2_various_06_21.txt",
                "HuGaDB_v2_various_06_22.txt",
                "HuGaDB_v2_various_06_23.txt",
                "HuGaDB_v2_various_06_24.txt",
                "HuGaDB_v2_various_06_25.txt",
                "HuGaDB_v2_various_06_26.txt",
                "HuGaDB_v2_various_06_27.txt",
            ],

            # variablenames
            [
                "acc_rf_x",
                "acc_rf_y",
                "acc_rf_z",
                "gyro_rf_x",
                "gyro_rf_y",
                "gyro_rf_z",
                "acc_rs_x",
                "acc_rs_y",
                "acc_rs_z",
                "gyro_rs_x",
                "gyro_rs_y",
                "gyro_rs_z",
                "acc_rt_x",
                "acc_rt_y",
                "acc_rt_z",
                "gyro_rt_x",
                "gyro_rt_y",
                "gyro_rt_z",
                "acc_lf_x",
                "acc_lf_y",
                "acc_lf_z",
                "gyro_lf_x",
                "gyro_lf_y",
                "gyro_lf_z",
                "acc_ls_x",
                "acc_ls_y",
                "acc_ls_z",
                "gyro_ls_x",
                "gyro_ls_y",
                "gyro_ls_z",
                "acc_lt_x",
                "acc_lt_y",
                "acc_lt_z",
                "gyro_lt_x",
                "gyro_lt_y",
                "gyro_lt_z",
                "EMG_r",
                "EMG_l",
                "act",
            ],

            # lambda function to assign a numerical ID to each activity/class
            class -> findfirst(
                activity -> class == activity,
                [
                    "walking",
                    "running",
                    "going_up",
                    "going_down",
                    "sitting",
                    "sitting_down",
                    "standing_up",
                    "standing",
                    "bicycling",
                    "elevator_up",
                    "elevator_down",
                    "sitting_car",
                ],
            ),
        )
    end
end

"""
    expfiles(l::HuGaDBLoader)

Retrieve the specific files to be loaded.
"""
expfiles(l::HuGaDBLoader) = l.expfiles

"""
    variablenames(l::HuGaDBLoader) = l.variablenames

Retrieve all the names of the columns for HuGaDB dataset.
"""
variablenames(l::HuGaDBLoader) = l.variablenames

"""
    activity2id(l::HuGaDBLoader, class::String) = l.activity2id(class)

Convert a specific variable name to an ID.
For example, convert "acc_rf_x" to 1.
"""
activity2id(l::HuGaDBLoader, class::String) = l.activity2id(class)

# load a single instance of HuGaDB dataset;
# driver code is load(::HuGaDBLoader)
function _load_hugadb(
    dirpath::S, filename::S; _variablenames::Vector{S}
) where {S<:AbstractString}
    filepath = joinpath(dirpath, filename)

    # e.g. open("test/data/HuGaDB/HuGaDB_v2_various_01_00.txt", "r")
    f = open(filepath, "r")

    # get the activities recorded for the performer specified in `filename`
    activities = split(readline(f), " ")[1:(end - 1)]
    activities[1] = activities[1][11:end] # remove the initial "#Activity\t"

    # activity strings to ids as in the table at https://github.com/romanchereshnev/HuGaDB
    _activity2id =
        x -> findfirst(
            activity -> x == activity,
            [
                "walking",
                "running",
                "going_up",
                "going_down",
                "sitting",
                "sitting_down",
                "standing_up",
                "standing",
                "bicycling",
                "elevator_up",
                "elevator_down",
                "sitting_car",
            ],
        )
    activity_ids = [_activity2id(activity) for activity in activities]

    # ignore #ActivityID array (we only keep the string version instead of integer IDs)
    readline(f)

    # ignore #Date row
    readline(f)

    # ignore the variable names, as we already explicited them in `_variablenames`
    readline(f)

    _substr2float = x -> parse(Float64, x)
    lines = [_substr2float.(split(line, "\t")) for line in eachline(f)]

    close(f)

    X = DataFrame(
        [
            # get the i-th element from each line, and concatenate them together
            [[line[i] for line in lines]] for i in 1:length(_variablenames)
        ], _variablenames
    )

    # _variablenames is returned to help the user, for example to let him know our default
    # values if he did not provide any.
    return X, (activities, activity_ids), _variablenames
end

"""
    function load(l::HuGaDBLoader)

Load HuGaDB dataset, as specified by the [`HuGaDBLoader`](@ref);
in particular, load the files returned by [`expfiles`](@ref).

See also [`expfiles(l::HuGaDBLoader)`], [`filter_hugadb`](@ref).
"""
function load(l::HuGaDBLoader)
    artifact_path = ensure_artifact_installed(name(l), ARTIFACTS_PATH)

    dirpath = begin
        tarfile = joinpath(artifact_path, "$(name(l)).tar.gz")
        if isfile(tarfile)
            extracted_path = extract_artifact(artifact_path, name(l))
            joinpath(extracted_path, "$(name(l))")
        else
            joinpath(artifact_path, "$(name(l))")
        end
    end

    # leverage the first instance to get, once for all, the common outputs such as
    # the list of activities (as pairs string/id pairs) and the names of each column.
    X, (activity_strings, activity_ids), _ = _load_hugadb(
        dirpath, expfiles(l)[1]; _variablenames=variablenames(l)
    )

    # return the concatenation of each DataFrame obtained by a `_load_hugadb` call
    return vcat(
        [
            X,
            [
                first(_load_hugadb(dirpath, filename; _variablenames=variablenames(l))) for
                filename in expfiles(l)[2:end]
            ]...,
        ]...,
    ),
    (activity_strings, activity_ids),
    variablenames(l)
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
    nvariables = last(size(X))

    # pick only the instances for which an `id` type of movement is recorded
    _X = (x -> filter(!isnothing, x))([
        let indices = findall(x -> x == id, X[instance, labelcolumn])
            if isempty(indices)
                nothing
            else
                DataFrame(
                    [[X[instance, variable][indices]] for variable in 1:nvariables],
                    variablenames,
                )
            end
        end for instance in 1:(first(size(X)))
    ])

    # concatenate all the picked instances in an unique DataFrame
    _Xfiltered = vcat(_X...)

    # we want to trim every recording to have the same length across instances;
    # since, when selecting an instance, each column of the latter has the same length,
    # we arbitrarily choose to compute the minimum length starting from the first column.
    minimum_length = minimum(length.(_Xfiltered[:, 1]))
    for instance in 1:(first(size(_Xfiltered)))
        for variable in 1:nvariables
            _Xfiltered[instance, variable] = _Xfiltered[instance, variable][1:minimum_length]
        end
    end

    return _Xfiltered
end
