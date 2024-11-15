```@meta
CurrentModule = SoleData
```

# SoleData

Welcome to the documentation for [SoleData](https://github.com/aclai-lab/SoleData.jl).

```@index
```

# Logical foundations

Here are some core concepts for symbolic artificial intelligence with propositional and modal logics.o

```@docs
SoleLogics.Atom
SoleLogics.AbstractWorld
SoleLogics.Interval
SoleLogics.Interval2D
SoleLogics.syntaxstring
SoleLogics.IA_L
SoleLogics.AbstractFrame
SoleLogics.accessibles
minify
```

See [SoleLogics](https://github.com/aclai-lab/SoleLogics.jl) for more.

# API

Ontop of the logical layer, we define features, conditions on features, logisets, and memosets.
```@autodocs
Modules = [SoleData]
Pages   = ["types/features.jl", "types/conditions.jl", "types/logiset.jl", "types/memoset.jl"]
```

```@docs
AbstractModalLogiset
AbstractScalarOneStepRelationalMemoset
```

# Utilities
## Logisets

```@autodocs
Modules = [SoleData]
Pages   = ["utils/features.jl", "utils/conditions.jl"]
```

```@autodocs
Modules = [SoleData]
Pages   = ["utils/logiset.jl", "utils/modal-logiset.jl"]
```
```@autodocs
Modules = [SoleData]
Pages   = ["utils/memoset.jl"]
```

```@docs
ScalarOneStepMemoset
```

```@autodocs
Modules = [SoleData]
Pages   = ["utils/supported-logiset.jl"]
```

```@autodocs
Modules = [SoleData]
Pages   = ["check.jl"]
```

### Scalar Logisets


```@autodocs
Modules = [SoleData]
Pages   = [
	"scalar/main.jl",
	"scalar/var-features.jl",
	"scalar/test-operators.jl",
	"scalar/conditions.jl",
	"scalar/templated-formulas.jl",
	"scalar/random.jl",
	"scalar/canonical-conditions.jl",
	"scalar/logiseed.jl",
	"scalar/scalarlogiset.jl",
	"scalar/autologiset-tools.jl",
	"scalar/memosets.jl",
	"scalar/onestep-memoset.jl",
	"scalar/propositional-logiset.jl",
	"scalar/propositional-formula-simplification.jl",
]
```

### Scalar Dimensional Logisets

```@autodocs
Modules = [SoleData, SoleData.DimensionalDatasets]
Pages   = [
	"dimensional-structures/main.jl",
	"dimensional-structures/logiset.jl",
	"dimensional-structures/onestep-memosets.jl",
	"dimensional-structures/computefeature.jl",
	"dimensional-structures/logiseeds/abstractdataframe.jl",
	"dimensional-structures/logiseeds/abstractdimensionaldataset.jl",
	"dimensional-structures/logiseeds/namedtuple.jl",
]
```

## Multimodal Logisets

```@autodocs
Modules = [SoleData]
Pages   = ["utils/multilogiset.jl",]
```

<!-- ## MLJ Integration

```@autodocs
Modules = [SoleData]
Pages   = ["types/logiset-MLJ-interface.jl",]
``` -->

# Optimizations
## Representatives

```@autodocs
Modules = [SoleData]
Pages   = [
	"types/representatives.jl",
	"scalar/representatives.jl",
]
```
