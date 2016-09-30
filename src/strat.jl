# SETUP ########################################################################
workspace()
using Base.Dates
using Temporal
using Indicators
abstract Strategem

# CALCS ########################################################################
#TODO: control calc output names
#TODO: allow for multiple parameters

type Calc <: Strategem
    fun::Function
    input::Vector{Symbol}
    par::Expr
    rng::AbstractArray
    lag::Bool
    function Calc(fun::Function, input::Vector{Symbol}, par::Expr, rng::AbstractArray=0:0, lag::Bool=true)
        new(fun, input, par, rng, lag)
    end
end
Calc(fun::Function, input::Symbol, par::Expr, rng::AbstractArray=0:0, lag::Bool=true) = Calc(fun, [input], par, rng, lag)

# SIGNALS ######################################################################
type Order <: Strategem
    qty::Int
    lim::Bool
    prc::Real
end
type Rule <: Strategem
    when::Expr
    exec::Order
end

# SIMULATIONS ##################################################################
anydt(t::Vector{TimeType})::Bool = any(map((ti)->isa(ti,DateTime), t))
todt!(t::Vector{TimeType}) = map!(DateTime, t)
function getidx(universe::Dict{Symbol,TS})::Vector
    t = Vector{TimeType}
    @inbounds for (key,val) in universe
        t = union(t, val.index)
    end
    anydt(t) ? todt!(t) : nothing
    return t
end
type Strategy <: Strategem
    universe::Dict{Symbol,TS}
    calcs::Dict{Symbol,Calc}
    rules::Dict{Symbol,Rule}
    account::TS
    portfolio::TS
    function Strategy(universe, calcs, rules)
        k = length(universe)
        n = length(t)
        t = getidx(universe)
        acct = ts(zeros(Float64, (n,1)), t, :Account)  # time series of total account value
        port = zeros(Int, (n,k), collect(keys(universe)))  # time series of qty held of each asset
    end
end
function addcalc!(strat::Strategy, name::Symbol, calc::Calc)
    strat.calcs[name] = calc
end
function addrule!(strat::Strategy, name::Symbol, rule::Rule)
    strat.rules[name] = rule
end

