abstract Order

type Transaction
    asset::Asset
    qty::Real
    price::Real
    value::Real
    fees::Real
end

#TODO: other order types (limit, stop, etc)
type MarketOrder <: Order
    timestamp::TimeType
    qty::Vector{Real}
    filled::Bool
    qty_remaining::Vector{Real}
    avg_fill_price::Vector{Float64}
    price_start::Vector{Float64}
    price_final::Vector{Float64}
end


#TODO: allow quantities to be determined by the portfolio/account object
# (this probably means defining methods where the `q` argument is some type of expression or function
function order!(B, a::Symbol, q::Number, dt::Date)::Void
    # B = [B; ts([a q], [dt], [:Asset,:Quantity])]
    B.values = [B.values; [a q]]
    B.index = [B.index; dt]
    return nothing
end

function fill!(ord::Order, txn::Transaction)::Void
    @assert ord.asset == txn.asset "Transaction asset inconsistent with order asset."
    @assert txn.qty <= ord.qty_remaining "Transaction quantity too high for order."
    #TODO: fill out avg price, value, and pnl calculations (and update filled status)
    ord.avg_price =
        (ord.avg_price*(ord.qty-ord.qty_remaining) + txn.price*txn.qty) /
        (txn.qty * (ord.qty-ord.qty_remaining))
    ord.qty_remaining -= txn.qty
    if ord.qty_remaining == 0
        ord.filled = 1
    end
    ord.value += txn.price * txn.qty
    return nothing
end

