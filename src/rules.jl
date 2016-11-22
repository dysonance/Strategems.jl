# ORDER TYPES ##################################################################
#TODO: implement more order types
type Order <: Strategem
    kind::Symbol
    qty::Int64
    prc::Float64
    function Order(kind, qty, prc)
        @assert kind in (:Market, :Limit)
        new(kind, qty, prc)
    end
end

# RULES ########################################################################
type Rule <: Strategem
    when::Symbol
    order::Order
end
