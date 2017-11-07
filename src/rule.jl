#=
Type and methods facilitating simple but effective syntax interface for defining trading rules
=#

#TODO: figure out how to make this a function that interfaces with the portfolio & account objects
mutable struct Rule
    trigger::Symbol
    action::Expr
end

macro rule(logic::Expr, args...)
    dump(logic)
    for i in 1:length(args)
        println(args[i])
    end
    return logic
end
