```@meta
DocTestSetup = :(using Survival, StatsBase)
CurrentModule = Survival
```

# Survival.jl

This package provides types and methods for performing
[survival analysis](https://en.wikipedia.org/wiki/Survival_analysis) in Julia.

## Installation

The package is not yet registered in Julia's General package registry, and so it must
be installed using `Pkg.add(PackageSpec(url="https://github.com/JuliaStats/Survival.jl"))`.

## Contents

```@contents
Pages = [
    "events.md",
    "km.md",
    "na.md",
    "cox.md",
]
Depth = 1
```
