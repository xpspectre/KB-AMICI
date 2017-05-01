# KroneckerBio-AMICI

A simpler, faster, limited KroneckerBio that uses AMICI/Sundials solvers.

AMICI (Advanced Matlab Interface to CVODES and IDAS) can be found at https://icb-dcm.github.io/AMICI/.

## Requirements

A C/C++ compiler is needed.

This was tested on Matlab R2016a.

## Setup

Run the `init.m` script in the root directory. This just runs AMICI's setup script which adds necessary paths.

## Running

The `test_eq_model.m` and `test_cascade_model.m` scripts are initial tests for getting a feel for how AMICI works.

The `test_eq_model_api.m` script builds the equilibrium model again using the `Model` class and simulates and fits using the newly-developed API.