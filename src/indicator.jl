mutable struct Indicator
    fun::Function
    paramset::ParameterSet
    data::TS
    function Indicator(fun::Function, paramset::ParameterSet)
        data = TS()
        return new(fun, paramset, data)
    end
end

function calculate!(indicator::Indicator, input::TS)::Void
    indicator.data = indicator.fun(input; generate_dict(indicator.paramset)...)
    return nothing
end

#TODO: show method
