# PorousMaterialResampling.jl
[![CI](https://github.com/shamazmazum/PorousMaterialResampling.jl/actions/workflows/test.yml/badge.svg)](https://github.com/shamazmazum/PorousMaterialResampling.jl/actions/workflows/test.yml)

This package uses Phase Recovery algorithm and resampling of autocorrelation
function to reconstruct 3D two-phase porous materials (internally represented as
three-dimensional arrays of `Bool`) from a set of 2D slices.

## Archive format

2D slices and additional metadata are stored in a zip archive. The metadata is a
JSON file `data/manifest.json` with the following schema:

~~~~{.json}
{
    "amount": 50,
    "denominator": 1,
    "prefix": "sample-10",
    "numerator": 10
}
~~~~

`"amount"` contains the number of slices in the
archive. `"numerator"/"denominator"` is the resampling ratio, i.e. how much
slices you need to reconsturct to get the original data. In this particular
case you need to recreate `(10/1 - 1)*50 = 450` slices. The slices themselves
are stored in PNG format and have names like `data/prefix-N.png` where `prefix`
is taken from the metadata and `N` is counting from `1` to `amount`. In this
example the slices have names `data/sample-10-1.png`, `data/sample-10-2.png`, …,
`data/sample-10-50.png`.

## How to use

Firstly, you create an archive of slices and secondly you run a function
`reconstruct` from this package. There is also a helper function, `archive`, to
create archives from three-dimensional data (kinda inverse problem).
