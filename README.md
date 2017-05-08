# KroneckerBio-AMICI

A simpler, faster, limited KroneckerBio that uses AMICI/Sundials solvers.

AMICI (Advanced Matlab Interface to CVODES and IDAS) can be found at https://icb-dcm.github.io/AMICI/.

## Requirements

A C/C++ compiler is needed.

This was tested on Matlab R2016a.

## Setup

Run the `init.m` script in the root directory. This adds the root dir and runs AMICI's setup script which adds necessary sub-dirs.

## Running Examples

### Simple Equilibrium Model

See file `test_eq_model_api.m`.

### Model with Fit Initial Conditions

See file `test_eq_model_fit_ic_api.m`.

### Multiple Model/Variants and Fitting

See file `test_eq_model_variants.m`.

### Variable-size Model

See file `test_cascade_model_api.m`. This is useful for testing out a very large model.

## Notes

Compared to KroneckerBio, this code is better at doing the subset of stuff I usually do, and can't do the stuff I don't usually do.

### Advantages

- Faster running time using Sundials/CVODES for the integrator
	- Uses fmincon with analytic gradient from sensitivity equations - same as KroneckerBio
- Simpler interface with states `x` and parameters `p`, replacing the 4 different types of params in KroneckerBio
- Implements the multi-experiment API from my `kroneckerbio/mixed-effects-fitting` branch.
	- But the specification of parameter relationships between models is much simpler using the Model/ModelVariant/Fit objects here compared to the Model/Experiment/Objective structs in KroneckerBio.

### Disadvantages

Lots of these are work-in-progress.
- Only supports the equivalent of `observationLinearWeightedSumOfSquares` objective function - built-in in AMICI. This is the most useful one, though.
- Building models is slow - it requires C cross-compilation to make MEX files. Run the `test_cascade_model_api.m` with a large `N` to benchmark.
    - Building and running large models (cascade model with N>100) may be prohibitively slow. Need to check KroneckerBio's performance on similar.
- Missing lots of the features in KroneckerBio, especially arbitrary inputs. TODO: Arbitrary stepwise inputs using sums of heaviside functions.
- State and parameter names must be valid identifiers. Working on a preprocessor to allow arbitrary names (if they're escaped in double-quotes, like in KroneckerBio)

## Scratch

The `test_eq_model.m`, `test_cascade_model.m`, and `test_fit_ic.m` scripts are initial tests for getting a feel for how AMICI works. They call `eq_model.m`, `cacade_model.m`, and `eq_model_fit_ic.m`, respectively, which use the AMICI API directly.

