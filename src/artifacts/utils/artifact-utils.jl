# This file contains all the methods necessary to automatically generate a functioning
# Artifacts.toml.
#
# For more information see the official documentation at:
# https://pkgdocs.julialang.org/v1/artifacts/#The-Pkg.Artifacts-API
# https://pkgdocs.julialang.org/v1/api/#Artifacts-Reference


"""
    fillartifacts()
    fillartifacts(URLS::Vector{String})
    function fillartifacts(url::String)

Completely automatize the insertion of a new resource into the Artifacts.toml file.

After the execution of the following command, the Artifacts.toml is updated as below;
note that the new entry is named with using the lowercase version of the resource name
provided.

```julia
julia> fillartifacts("https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/NATOPS.tar.gz")
```
[natops]
git-tree-sha1 = "87856b9b41a235ec57f36d1029d0467876660e6e"

    [[natops.download]]
    url = "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/NATOPS.tar.gz"
    sha256 = "2586be714b4112b874d050dd3f873e12156d1921e5ded9bd8f66bf5bf8d9c2d1"
"""
function fillartifacts()
    fillartifacts(ARTIFACT_URLS)
end
function fillartifacts(URLS::Vector{String})
    map(url -> fillartifacts(url), URLS)
end
function fillartifacts(url::String)
    filename_with_extension = split(url, "/")[end]
    filename_no_extension = split(filename_with_extension, ".")[1] |> lowercase

    # see https://pkgdocs.julialang.org/v1/artifacts/#The-Pkg.Artifacts-API
    # this is ambiguous: create_artifact expects a function F as argument;
    # the argument passed to F is a temporary directory in which we must download our things
    # and, then, Pkg.Artifacts will move our things to a specific directory in
    # .julia/artifacts folder.

    # download the file in a temporary location to compute its SHA256;
    # WARNING: the file is created here... and then copied from here with cp!
    temp_file = tempname()
    Downloads.download(url, temp_file)
    file_sha256 = bytes2hex(open(sha256, temp_file))

    # create the artifact
    SHA1 = create_artifact(
        tmp_dir -> Downloads.download(url, joinpath(tmp_dir, filename_with_extension)))

    # now we can clear the temporary file
    rm(temp_file)

    # and bind the artifact to let the user call the macro artifact"name"
    bind_artifact!(ARTIFACTS_PATH, filename_no_extension, SHA1; force=true)

    # proceed to update the Artifact.toml
    content = TOML.parsefile(ARTIFACTS_PATH)
    open(ARTIFACTS_PATH, "w") do tomlfile
        # eg: Dict{String, Any} with 1 entry:
        #  "natops" => Dict{String, Any}(
        #       "git-tree-sha1"=>"87856b9b41a235ec57f36d1029d0467876660e6e",
        #       "download"=>Any[Dict{String, Any}("sha256"=>"2586be714b4…

        if "download" in keys(content[filename_no_extension])
            @warn "Entry $(entry) already exists."
        else
            # we insert a vector of possible new entries; this method automatically infers
            # the most simple one but actually it could be possible to add many sources;
            # to do so, we could iterate some kwargs here.
            new_entry = Dict{String,Any}()
            content[filename_no_extension]["download"] = [new_entry]
            new_entry["sha256"] = bytes2hex(open(sha256, artifact_path(SHA1)))
            new_entry["url"] = url
        end

        redirect_stdout(tomlfile) do
            TOML.print(content)
        end
    end

end
