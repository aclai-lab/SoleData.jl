<div align="center">[<img src="logo.png" alt="" title="This package is part of Sole.jl" width="200" />](https://github.com/aclai-lab/Sole.jl)</div>

# SoleData.jl – Unstructured and Multimodal datasets

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aclai-lab.github.io/SoleData.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleData.jl/dev)
[![Build Status](https://api.cirrus-ci.com/github/aclai-lab/SoleData.jl.svg?branch=main)](https://cirrus-ci.com/github/aclai-lab/SoleData.jl)
[![Coverage](https://codecov.io/gh/aclai-lab/SoleData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/aclai-lab/SoleData.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aclai-lab.github.io/SoleData.jl/dev) -->

## In a nutshell

*SoleData* provides a **machine learning oriented** data layer on top of DataFrames.jl/Tables.jl for:
- Instantiating and manipulating [*multimodal*](https://en.wikipedia.org/wiki/Multimodal_learning) datasets for (un)supervised machine learning;
- Dealing with [*(un)structured* data](https://en.wikipedia.org/wiki/Unstructured_data) (e.g., graphs, images, time-series, etc.);
- Describing datasets via basic statistical measures;
- Saving to/loading from *npy/npz* format, as well as a custom CSV-based format (with interesting features such as *lazy loading* of datasets);
- Performing basic data processing operations (e.g., windowing, moving average, etc.).

If you are used to dealing with unstructured/multimodal data, but cannot find the right
tools in Julia, you will find
[*SoleFeatures.jl*](https://github.com/aclai-lab/SoleFeatures.jl/) useful!

## About

The package is developed by the [ACLAI Lab](https://aclai.unife.it/en/) @ University of
Ferrara.

*SoleData.jl* was originally built as the data layer for
[*Sole.jl*](https://github.com/aclai-lab/Sole.jl), an open-source framework for
*symbolic machine learning*.
