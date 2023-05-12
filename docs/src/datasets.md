```@meta
CurrentModule = SoleData
```

# [Datasets](@id man-datasets)

```@contents
Pages = ["datasets.md"]
```

Machine learning datasets are a collection of samples (or instances),
each one described by a number of variables.
In the case of *tabular* data, a dataset looks like
a database table, where every column is a variable,
and each row corresponds to a given instance. However, a dataset can also be *non-tabular*
(or *unstructured*); for example, each instance can consist of a multivariate time-series, or
an image.

When data is composed of different
[modalities](https://en.wikipedia.org/wiki/Modality_(human%E2%80%93computer_interaction))
combining their statistical properties is non-trivial, since they may be quite different in nature
one another.
<!-- To keep different modalities separated, while keeping the data
easily manageable, SoleData provides a general way yo handle this kind of data. -->

The abstract representation of a multimodal dataset provided by this package is the
[`AbstractMultiFrameDataset`](@ref).

```@docs
AbstractMultiFrameDataset
frame_descriptor
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
<!-- Datasets that consist not labeled examples, meaning that each instance contains only
features but it is not associated with label are known as _unsupervised datasets_.
 -->
Multimodal *unlabeled* datasets can be instantiated with [`MultiFrameDataset`](@ref).

<!-- ### [MultiFrameDataset](@id man-MultiFrameDataset) -->

```@autodocs
Modules = [SoleData]
Pages = ["src/MultiFrameDataset.jl"]
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

As an extension of the [`AbstractMultiFrameDataset`](@ref),
[`AbstractLabeledMultiFrameDataset`](@ref) has an interface that can be implemented to
represent multimodal labeled datasets.

```@docs
AbstractLabeledMultiFrameDataset
labels_descriptor
dataset
```

Multimodal *labeled* datasets can be instantiated with [`LabeledMultiFrameDataset`](@ref).

```@autodocs
Modules = [SoleData]
Pages = ["LabeledMultiFrameDataset.jl", "labels.jl"]
```
