#=
Type and methods facilitating simple but effective syntax interface for defining trading rules
=#

#TODO: figure out how to make this a function that interfaces with the portfolio & account objects
mutable struct Rule
    trigger::Expr
    action::Expr
    function Rule(trigger::Expr, action::Expr)
        @assert typeof(eval(trigger.args[1])) <: Function
        return new(trigger, action)
    end
end

↑(x, y) = Indicators.crossover(x, y)
↓(x, y) = Indicators.crossunder(x, y)

function prep_trigger(rule::Rule, indicator::Indicator)::Expr
    local trigger = copy(rule.trigger)
    for i in 2:length(trigger.args)
        trigger.args[i] = indicator.data[trigger.args[i]]
    end
    return trigger
end
