#=
Type and methods facilitating simple but effective syntax interface for defining trading rules
=#

#TODO: figure out how to make this a function that interfaces with the portfolio & account objects
mutable struct Rule
    trigger::Symbol
    action::Expr
end

