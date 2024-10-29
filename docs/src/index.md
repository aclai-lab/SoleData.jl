```@meta
CurrentModule = SoleData
```

# SoleData

Welcome to the documentation for [SoleData](https://github.com/aclai-lab/SoleData.jl).

```@index
```

# Logical foundations

See [SoleLogics](https://github.com/aclai-lab/SoleLogics.jl) for more.
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

# Logisets

```@autodocs
Modules = [SoleData]
Pages   = ["features.jl", "conditions.jl"]
```

```@autodocs
Modules = [SoleData]
Pages   = ["representatives.jl"]
```
```@autodocs
Modules = [SoleData]
Pages   = ["logiset.jl"]
```
```@autodocs
Modules = [SoleData]
Pages   = ["memosets.jl"]
```

```@docs
AbstractModalLogiset
AbstractScalarOneStepRelationalMemoset
ScalarOneStepMemoset
```

```@autodocs
Modules = [SoleData]
Pages   = ["supported-logiset.jl"]
```

```@autodocs
Modules = [SoleData]
Pages   = ["check.jl"]
```

## Scalar Logisets

```@autodocs
Modules = [SoleData]
Pages   = [
	"scalar/main.jl",
	"scalar/var-features.jl",
	"scalar/test-operators.jl",
	"scalar/conditions.jl",
	"scalar/templated-formulas.jl",
	"scalar/random.jl",
	"scalar/representatives.jl",
	"scalar/canonical-conditions.jl",
	"scalar/dataset-bindings.jl",
	"scalar/memosets.jl",
	"scalar/onestep-memoset.jl",
	"scalar/propositional-logiset.jl",
	"scalar/propositional-formula-simplification.jl",
]
```

## Scalar Dimensional Logisets

```@autodocs
Modules = [SoleData, SoleData.DimensionalDatasets]
Pages   = [
	"dimensional-structures/main.jl",
	"dimensional-structures/logiset.jl",
	"dimensional-structures/onestep-memosets.jl",
	"dimensional-structures/computefeature.jl",
	"dimensional-structures/dataset-bindings.jl",
]
```

# Multimodal Logisets

```@autodocs
Modules = [SoleData]
Pages   = ["multilogiset.jl"]
```
