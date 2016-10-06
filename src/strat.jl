# SETUP ########################################################################
anydt(t::Vector{TimeType})::Bool = any(map((ti)->isa(ti,DateTime), t))
todt!(t::Vector{TimeType}) = map!(DateTime, t)
function initsigs(universe::Dict{Symbol,TS}, rules::Dict{Symbol,Rule})::Dict{Symbol,TS}
    nrules = length(rules)
    sigs = Dict{Symbol,TS}()
    @inbounds for (key,val) in universe
        sigs[key] = ts(falses((size(val,1),nrules)), val.index, collect(keys(rules)))
    end
    return sigs
end
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
    signals::Dict{Symbol,TS}
    account::TS
    portfolio::TS
    function Strategy(universe, calcs, rules)
        k = length(universe)
        n = length(t)
        t = getidx(universe)
        acct = ts(zeros(Float64, (n,k)), t, :Account)  # time series of total account value
        port = ts(zeros(Int, (n,k)), t, collect(keys(universe)))  # time series of qty held of each asset
        sigs = initsigs(universe, rules)
    end
end
function addcalc!(strat::Strategy, name::Symbol, calc::Calc)
    strat.calcs[name] = calc
    nothing
end
function addrule!(strat::Strategy, name::Symbol, rule::Rule)
    strat.rules[name] = rule
    nothing
end
