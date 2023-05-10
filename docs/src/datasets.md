```@meta
CurrentModule = SoleData
```

# [Datasets](@id man-datasets)

```@contents
Pages = ["datasets.md"]
```

A dataset is a collection of data. In the case of tabular data, a data set corresponds to
one or more database tables, where every column of a table represents a particular variable,
and each row corresponds to a given record of the data set in question. The data set lists
values for each of the variables, such as for example height and weight of an object, for
each member of the data set. Data sets can also consist of a collection of documents or
files.

When data is composed by different
[modalities](https://en.wikipedia.org/wiki/Modality_(human%E2%80%93computer_interaction))
it is non-trivial combining their statistical properties since they may be very different
one another. To keep separated different modalities of the data while keeping the data
easily manageable here we provide a general way yo handle this kind of data.

The abstract representation of a multi-modal dataset provided by this package is the
[`AbstractMultiFrameDataset`](@ref).

```@docs
AbstractMultiFrameDataset
frame_descriptor
data
dimension
```

## [Unsupervised](@id man-unsupervised)

Datasets that consist not labeled examples, meaning that each data point contains only
features but it is not associated with label are known as _unsupervised datasets_.

Multi-modal _unsupervised_ datasets are represented by [`MultiFrameDataset`](@ref).

### [MultiFrameDataset](@id man-MultiFrameDataset)

```@autodocs
Modules = [SoleData]
Pages = ["src/MultiFrameDataset.jl"]
```

## [Supervised](@id man-supervised)

Datasets that consist of labeled examples, meaning that each data point contains features
and an associated label are known as _supervised datasets_.

As an extension of the [`AbstractMultiFrameDataset`](@ref) the
[`AbstractLabeledMultiFrameDataset`](@ref) is an interface that can be implemented to
represent multi-modal _supervised_ datasets.

```@docs
AbstractLabeledMultiFrameDataset
labels_descriptor
dataset
```

Multi-modal _supervised_ datasets are represented by [`LabeledMultiFrameDataset`](@ref).

### [LabeledMultiFrameDataset](@id man-LabeledMultiFrameDataset)

```@autodocs
Modules = [SoleData]
Pages = ["LabeledMultiFrameDataset.jl", "labels.jl"]
```
