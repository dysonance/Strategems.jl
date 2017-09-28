mutable struct Blotter
    orders::Vector{Order}
end

#TODO: resolve inconsistency -- is blotter a TS object or its own type?
function init_blotter()::TS{Any,Date}
    B = ts{Any,Date}([:None 0], [Date(0)], [:Asset, :Quantity])
end
#blotter = init_blotter()

#TODO: decide if this should be outsourced to Portfolio logic?
function get_total_position(B, a::Symbol)::Number
    n = size(B, 1)
    A = Symbol.(B[:Asset].values)
    Q = Number.(B[:Quantity].values)
    q = 0
    @inbounds for i in 1:n
        if A[i] == a
            q += Q[i]
        end
    end
    return q
end

liquidate!(B, a::Symbol, dt::Date)::Void = order!(B, a, -get_total_position(B,a), dt)
