
import Base: show

struct Indicator
    fun::Function
    paramset::ParameterSet
    data::TS
    function Indicator(fun::Function, paramset::ParameterSet, data::TS)
        return new(fun, paramset, data)
    end
end

function Indicator(fun::Function, paramset::ParameterSet)
    return Indicator(fun, paramset, TS())
end

function calculate(indicator::Indicator, input::TS; arg_values::Vector)::TS
    return indicator.fun(input; generate_dict(indicator.paramset, arg_values)...)
end

# function calculate!(indicator::Indicator, input::TS)::Nothing
#     indicator.data = calculate(indicator, input)
#     return nothing
# end

# function generate_dict(universe::Universe, indicator::Indicator)::Dict{String,Indicator}
#     indicators = Dict{String,Indicator}()
#     for asset in universe.assets
#         local ind = Indicator(indicator.fun, indicator.paramset)
#         calculate!(ind, universe.data[asset])
#         indicators[asset] = ind
#     end
#     return indicators
# end

# TODO: add information about the calculation function
function show(io::IO, indicator::Indicator)
    show(io, indicator.paramset)
end
