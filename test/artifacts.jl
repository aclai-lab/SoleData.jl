using SoleData.Artifacts
using SoleData.Artifacts: load

# fill your Artifacts.toml file;
@test_nowarn fillartifacts()


# Loader lists
abcloader = ABCLoader()
mitloader = MITESPRESSOLoader()
epilepsyloader = EpilepsyLoader()
hugadbloader = HuGaDBLoader()
librasloader = LibrasLoader()
natopsloader = NatopsLoader()

LOADERS = [
    abcloader,
    mitloader,
    epilepsyloader,
    hugadbloader,
    librasloader,
    natopsloader,
]


# Common logic
for l in LOADERS
    printstyled("Loading $(name(l))\n", color=:green)

    # this should be enough to also test the specific getters of each loader since,
    # if they exist, they are called by the loading logic.
    @test_nowarn load(l)
end
