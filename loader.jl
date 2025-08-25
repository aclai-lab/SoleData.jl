# This file contains all the methods necessary to automatically generate a functioning
# Artifacts.toml.
#
# For more information see the official documentation at:
# https://pkgdocs.julialang.org/v1/artifacts/#The-Pkg.Artifacts-API
# https://pkgdocs.julialang.org/v1/api/#Artifacts-Reference

using Downloads
using Pkg.Artifacts
using SHA
using TOML


const ARTIFACTS_PATH = joinpath(@__DIR__, "Artifacts.toml")

# INSERT HERE YOUR ARTIFACT URLS: es "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/minimizers/mitespresso.tar.gz"
URLS = [
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/minimizers/mitespresso.tar.gz"
]

"""
    fill_artifacts(URLS::Vector{String})

Map of [`fill_artifacts(url::String)`](@ref).
"""
function fill_artifacts(URLS::Vector{String})
    map(url -> fill_artifacts(url), URLS)
end

"""
    function fill_artifacts(url::String)

Completely automatize the insertion of a new resource into the Artifacts.toml file.

After the execution of the following command, the Artifacts.toml is updated as below;
note that the new entry is named with using the lowercase version of the resource name
provided.

```julia
julia> fill_artifacts("https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/NATOPS.tar.gz")
```
[natops]
git-tree-sha1 = "87856b9b41a235ec57f36d1029d0467876660e6e"

    [[natops.download]]
    url = "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/NATOPS.tar.gz"
    sha256 = "2586be714b4112b874d050dd3f873e12156d1921e5ded9bd8f66bf5bf8d9c2d1"
"""
function fill_artifacts(url::String)
    filename_with_extension = split(url, "/")[end]
    filename_no_extension = split(filename_with_extension, ".")[1] |> lowercase

    # Prima scarica il file in un percorso temporaneo per calcolare il suo SHA256
    temp_file = tempname()
    Downloads.download(url, temp_file)
    file_sha256 = bytes2hex(open(sha256, temp_file))

    # Ora crea l'artifact
    SHA1 = create_artifact(
        tmp_dir -> cp(temp_file, joinpath(tmp_dir, filename_with_extension)))

    # Pulisci il file temporaneo
    rm(temp_file)

    bind_artifact!(ARTIFACTS_PATH, filename_no_extension, SHA1; force=true)

    # content of the ARTIFACTS_PATH
    content = TOML.parsefile(ARTIFACTS_PATH)

    open(ARTIFACTS_PATH, "w") do tomlfile
        # eg: Dict{String, Any} with 1 entry:
        #  "natops" => Dict{String, Any}(
        #       "git-tree-sha1"=>"87856b9b41a235ec57f36d1029d0467876660e6e",
        #       "download"=>Any[Dict{String, Any}("sha256"=>"2586be714b4…

        if "download" in keys(content[filename_no_extension])
            @warn "Entry $(filename_no_extension) already exists."
        else
            # we insert a vector of possible new entries; this method automatically infers
            # the most simple one but actually it could be possible to add many sources;
            # to do so, we could iterate some kwargs here.
            new_entry = Dict{String,Any}()
            content[filename_no_extension]["download"] = [new_entry]
            new_entry["sha256"] = file_sha256  # Usa l'hash del file originale
            new_entry["url"] = url
        end

        redirect_stdout(tomlfile) do
            TOML.print(content)
        end
    end
end
