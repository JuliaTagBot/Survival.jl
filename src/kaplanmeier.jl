abstract type AbstractEstimator end
abstract type NonparametricEstimator <: AbstractEstimator end

"""
    KaplanMeier(times, events)

Given a vector of times to events and a corresponding vector of indicators that
dictate whether each time is an observed event or is right censored, compute the
Kaplan-Meier estimate of the survivor function.

The estimate is given by
``
\\hat{S}(t) = \\prod_{i: t_i < t} \\left( 1 - \\frac{d_i}{n_i} \\right)
``
where ``d_i`` is the number of observed events at time ``t_i`` and ``n_i`` is
the number of subjects at risk just before ``t_i``.

### References

Kaplan, E. L., and Meier, P. (1958). *Nonparametric Estimation from Incomplete
Observations*. Journal of the American Statistical Association, 53(282), 457-481.
doi:10.2307/2281868
"""
struct KaplanMeier{T<:Real} <: NonparametricEstimator
    times::Vector{T}
    nevents::Vector{Int}
    ncensor::Vector{Int}
    natrisk::Vector{Int}
    survival::Vector{Float64}
end

# Internal Kaplan-Meier function with the following assumptions:
#  * The input array is sorted
#  * It is nonempty
#  * Time 0 is not included
function _km(tte::AbstractVector{T}, status::BitVector) where {T}
    nobs = length(tte)
    dᵢ = 0                # Number of observed events at time t
    cᵢ = 0                # Number of censored events at time t
    nᵢ = nobs             # Number remaining at risk at time t
    km = 1.0              # Ŝ(t)

    times = T[]           # The set of unique event times
    nevents = Int[]       # Total observed events at each time
    ncensor = Int[]       # Total censored events at each time
    natrisk = Int[]       # Number at risk at each time
    survival = Float64[]  # Survival estimates

    t_prev = zero(T)

    @inbounds for i = 1:nobs
        t = tte[i]
        s = status[i]
        # Aggregate over tied times
        if t == t_prev
            dᵢ += s
            cᵢ += !s
            continue
        elseif !iszero(t_prev)
            km *= 1 - dᵢ / nᵢ
            push!(times, t_prev)
            push!(nevents, dᵢ)
            push!(ncensor, cᵢ)
            push!(natrisk, nᵢ)
            push!(survival, km)
        end
        nᵢ -= dᵢ + cᵢ
        dᵢ = s
        cᵢ = !s
        t_prev = t
    end

    # We need to do this one more time to capture the last time
    # since everything in the loop is lagged
    push!(times, t_prev)
    push!(nevents, dᵢ)
    push!(ncensor, cᵢ)
    push!(natrisk, nᵢ)
    push!(survival, km)

    return KaplanMeier{T}(times, nevents, ncensor, natrisk, survival)
end


function StatsBase.fit(::Type{KaplanMeier},
                       times::AbstractVector{T},
                       status::AbstractVector{Bool}) where {T}
    p = sortperm(times)
    t = times[p]
    s = status[p]
    return _km(t, s)
end