#=
Type and methods facilitating simple but effective syntax interface for defining trading rules
=#

import Base: show

#TODO: figure out how to make this a function that interfaces with the portfolio & account objects
struct Rule{S,F,T}
    trigger::S
    action::F
    args::Tuple{Vararg{T}}
    function Rule(trigger::S, action::F, args::Tuple{Vararg{T}}) where {S<:Signal, F<:Function, T}
        return new{S,F,T}(trigger, action, args)
    end
end

macro rule(logic::Expr, args...)
    trigger = :($(logic.args[2]))
    #action = :($(logic.args[3])$((args...)))
    action = :($(logic.args[3]))
    args = :($(args))
    return esc(:(Rule($trigger, $action, $args)))
end

→(a,b) = a ? b() : nothing

function show(io::IO, rule::Rule)
    action_string = titlecase(split(string(rule.action), '.')[end])
    arg_string = titlecase(string(rule.args...))
    trigger_string = string(rule.trigger.switch)
    print(io, "$action_string $arg_string when $trigger_string")
end
