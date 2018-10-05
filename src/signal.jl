#=
type and methods for handling signals generating by consuming data exhaust from indicators
=#

struct Signal
    switch::Expr
    fun::Function
    function Signal(switch::Expr)
        @assert typeof(eval(switch.args[1])) <: Function
        a::Symbol = switch.args[2]
        b::Symbol = switch.args[3]
        #pair = eval(switch.args[1])::Function => Tuple{Symbol,Symbol}(switch.args[2]::Symbol, switch.args[3]::Symbol)
        #fun(x::TS)::BitVector = pair.first(x[pair.second[1]].values[:]::Vector, x[pair.second[2]].values[:]::Vector)
        function fun(x::TS)::BitVector
            #fld1::Symbol = switch.args[2]
            #fld2::Symbol = switch.args[3]
            vec1::Vector = x[a].values[:]
            vec2::Vector = x[b].values[:]
            comp::Function = eval(switch.args[1])
            if comp == ==
                comp(x,y) = broadcast(==, x, y)
            end
            out::BitVector = comp(vec1, vec2)
            return out
        end
        return new(switch, fun)
    end
end

function prep_signal(signal::Signal, indicator_data::TS)::Expr
    local switch = copy(signal.switch)
    for i in 2:length(switch.args)
        switch.args[i] = indicator_data[switch.args[i]]
    end
    return switch
end

macro signal(logic::Expr)
    return Signal(logic)
end

↑(x, y) = Indicators.crossover(x, y)
↓(x, y) = Indicators.crossunder(x, y)
