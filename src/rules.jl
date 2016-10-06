# SIGNALS ######################################################################
type Order <: Strategem
    qty::Int
    lim::Bool
    prc::Real
end
type Rule <: Strategem
    when::Expr
    exec::Order
end
