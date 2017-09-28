#=
type and methods for handling signals generating by consuming data exhaust from indicators
=#

mutable struct Signal
    switch::Expr
    function Signal(switch::Expr)
        @assert typeof(eval(switch.args[1])) <: Function
        return new(switch)
    end
end

function prep_signal(signal::Signal, indicator::Indicator)::Expr
    local switch = copy(signal.switch)
    for i in 2:length(switch.args)
        switch.args[i] = indicator.data[switch.args[i]]
    end
    return switch
end

↑(x, y) = Indicators.crossover(x, y)
↓(x, y) = Indicators.crossunder(x, y)
