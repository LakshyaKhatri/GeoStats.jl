## Copyright (c) 2017, Júlio Hoffimann Mendes <juliohm@stanford.edu>
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted, provided that the above
## copyright notice and this permission notice appear in all copies.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
## WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
## ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
## WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
## ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
## OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""
    KrigParam(variogram=v, mean=m, degree=d, drifts=ds)

A set of parameters for a Kriging variable.

## Parameters

* Set the mean `m` to use Simple Kriging
* Set the degree `d` to use Universal Kriging
* Set the drifts `ds` to use External Drift Kriging

Latter options override former options. For example, by specifying
`ds`, the user is telling the algorithm to ignore `d` and `m`.
If no option is specified, Ordinary Kriging is used by default.
"""
@with_kw struct KrigParam
  variogram = GaussianVariogram()
  mean = nothing
  degree = nothing
  drifts = nothing
end

"""
    Kriging(var1=>param1, var2=>param2, ...)

A polyalgorithm Kriging estimation solver.
"""
struct Kriging <: AbstractEstimationSolver
  params::Dict{Symbol,KrigParam}

  function Kriging(params...)
    new(Dict(params...))
  end
end

function solve(problem::EstimationProblem{D}, solver::Kriging) where {D<:AbstractDomain}
  # sanity checks
  @assert keys(solver.params) ⊆ variables(problem) "invalid variable names in solver parameters"

  # determine coordinate type
  geodata = data(problem)
  coordtypes = eltypes(coordinates(geodata))
  T = promote_type(coordtypes...)

  # loop over target variables
  for var in variables(problem)
    # retrieve valid data
    vardata = geodata[[var]]
    completecases!(vardata)

    # determine value type
    V = eltype(vardata.data[var])

    # get user parameters
    if var ∈ keys(solver.params)
      varparams = solver.params[var]
    else
      varparams = KrigParam()
    end

    # determine which Kriging variant to use
    if varparams.drifts ≠ nothing
      estimator = ExternalDriftKriging{T,V}(varaparams.variogram, varparams.drifts)
    elseif varparams.degree ≠ nothing
      estimator = UniversalKriging{T,V}(varparams.variogram, varparams.degree)
    elseif varparams.mean ≠ nothing
      estimator = SimpleKriging{T,V}(varparams.variogram, varparams.mean)
    else
      estimator = OrdinaryKriging{T,V}(varparams.variogram)
    end

    # perform estimation
    solve(problem, estimator, var)
  end
end

function solve(problem::EstimationProblem{D},
               estimator::E, var::Symbol) where {D<:AbstractDomain,E<:AbstractEstimator}
  # TODO: implement estimation loop
end