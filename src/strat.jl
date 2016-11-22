# SETUP ########################################################################
# Concatenate Symbol types like with strings for easy field naming
import Base: *, .*
*(a::Symbol, b::Symbol) = Symbol("$(string(a))_$(string(b))")
.*(a::Symbol, b::Vector{Symbol}) = map((sym)->a*sym, b)
.*(a::Vector{Symbol}, b::Symbol) = map((sym)->sym*b, a)

# STRATEGY TYPE DEFINITION #####################################################
abstract Strategem
type Result <: Strategem
    calcs::Dict{Symbol,TS}
    signals::Dict{Symbol,TS}
    function Result(calcs=Dict{Symbol,TS}(), signals=Dict{Symbol,TS}())
        new(calcs, signals)
    end
end
type Strategy <: Strategem
    universe::Dict{Symbol,TS}
    calcs::Dict{Symbol,Expr}
    signals::Dict{Symbol,Expr}
    results::Result
    function Strategy(universe=Dict{Symbol,TS}(), calcs=Dict{Symbol,Expr}(), signals=Dict{Symbol,Expr}(), results=Result())
        new(universe, calcs, signals, results)
    end
end

# Generate the signals
function calculate!(strat::Strategy)
    @inbounds for (sym, data) in strat.universe
        print("Running calculations for asset $sym...")
        @inbounds for (name, calc) in strat.calcs
            tmparg = calc.args[2]
            calc.args[2] = :data
            tmp = eval(calc)
            calc.args[2] = tmparg
            # Adjust field names as appropriate
            if size(tmp,2) == 1
                tmp.fields = [name]
            else
                tmp.fields = name .* tmp.fields
            end
            # Add to strategy this asset's result set
            if !haskey(strat.results.calcs, sym)
                strat.results.calcs[sym] = tmp
            else
                strat.results.calcs[sym] = [strat.results.calcs[sym] tmp]
            end
        end
        # Generate signals for this asset
        @inbounds for (name, sig) in strat.signals
            if !haskey(strat.results.signals, sym)
                strat.results.signals[sym] =
                eval(sig.args[1])(strat.results.calcs[sym][sig.args[2]], strat.results.calcs[sym][sig.args[3]])
            else
                strat.results.signals[sym] =
                [strat.results.signals[sym] eval(sig.args[1])(strat.results.calcs[sym][sig.args[2]], strat.results.calcs[sym][sig.args[3]])]
            end
            strat.results.signals[sym].fields[end] = name
        end
        print("Done.\n")
    end
    nothing
end
