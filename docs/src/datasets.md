```@meta
CurrentModule = SoleData
```

# [Datasets](@id man-datasets)

```@contents
Pages = ["datasets.md"]
```

Machine learning datasets are a collection of instances (or samples),
each one described by a number of variables.
In the case of *tabular* data, a dataset looks like
a database table, where every column is a variable,
and each row corresponds to a given instance. However, a dataset can also be *non-tabular*
(or *unstructured*); for example, each instance can consist of a multivariate time-series, or
an image.

When data is composed of different
[modalities](https://en.wikipedia.org/wiki/Multimodal_learning))
combining their statistical properties is non-trivial, since they may be quite different in nature
one another.

The abstract representation of a multimodal dataset provided by this package is the
[`AbstractMultiModalDataset`](@ref).

```@docs
AbstractMultiModalDataset
grouped_variables
data
dimension
```

## [Unlabeled Datasets](@id man-unlabeled-datasets)

In *unlabeled datasets*
there is no label variable, and all of the variables (also called *feature variables*,
or *features*) have equal role in the representation.
These datasets are used in
[unsupervised learning](https://en.wikipedia.org/wiki/Unsupervised_learning) contexts,
for discovering internal correlation patterns between the features.
Multimodal *unlabeled* datasets can be instantiated with [`MultiModalDataset`](@ref).

```@autodocs
Modules = [SoleData]
Pages = ["src/MultiModalDataset.jl"]
```

## [Labeled Datasets](@id man-supervised-datasets)

In *labeled datasets*, one or more variables are considered to have special semantics
with respect to the other variables;
each of these *labeling variables* (or *target variables*) can be thought as assigning
a label to each instance, which is typically a categorical value (*classification label*)
or a numerical value (*regression label*).
[Supervised learning](https://en.wikipedia.org/wiki/Unsupervised_learning) methods
can be applied on these datasets
for modeling the target variables as a function of the feature variables.

As an extension of the [`AbstractMultiModalDataset`](@ref),
[`AbstractLabeledMultiModalDataset`](@ref) has an interface that can be implemented to
represent multimodal labeled datasets.

```@docs
AbstractLabeledMultiModalDataset
labeling_variables
dataset
```

Multimodal *labeled* datasets can be instantiated with [`LabeledMultiModalDataset`](@ref).

```@autodocs
Modules = [SoleData]
Pages = ["LabeledMultiModalDataset.jl", "labels.jl"]
```
