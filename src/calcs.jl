# CALCS ########################################################################
#TODO: control calc output names
#TODO: allow for multiple parameters

type Calc <: Strategem
    fun::Function
    input::Vector{Symbol}
    par::Expr
    rng::AbstractArray
    lag::Bool
    function Calc(fun::Function, input::Vector{Symbol}, par::Expr, rng::AbstractArray=0:0, lag::Bool=true)
        new(fun, input, par, rng, lag)
    end
end
Calc(fun::Function, input::Symbol, par::Expr, rng::AbstractArray=0:0, lag::Bool=true) = Calc(fun, [input], par, rng, lag)
