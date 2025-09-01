using SoleData.Artifacts

@test_nowarn fillartifacts()

nl = NatopsLoader()
X, y = load(nl)

@test classes(nl)
