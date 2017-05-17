using Temporal, Indicators

# ==== ASSETS ====
abstract Asset
#TODO: add currency conversion logic
type Currency <: Asset
    asset_id::Symbol
end
type Equity <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
end
type Forward <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::TimeType
end
Forward(id::Symbol,curr::Currency,mult::Real,min_tick::Real)=Forward(id,curr,mult,min_tick,Date(0))
type Option <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
    maturity::TimeType
    strike::Float64
    style::Symbol
end
type Bond <: Asset
    asset_id::Symbol
    currency::Currency
    multiplier::Real
    min_tick::Real
end

# ==== PORTFOLIOS/HOLDINGS =====
type Portfolio
    assets::Vector{Asset}
    holdings::TS{Real}  # columns are assets, rows are holdings
    values::TS{Real}  # columns are assets, rows are position values
    weights::TS{Real}  # columns are assets, rows are portfolio weights
end
function init_holdings(assets::Vector{Asset})::TS
    n_assets = length(assets)
    ids = Vector{Symbol}(n_assets)
    @inbounds for i in 1:n_assets
        ids[i] = assets[i].asset_id
    end
    holdings = ts(zeros(0,n_assets), Vector{Date}(), ids)
    return holdings
end

# ==== ACCOUNTS ====
type Account
    currency::Currency
    balance::Real
    ledger::TS{Float64}
end
init_ledger() = TS(zeros(Float64,0,3), Vector{Date}(), [:Credit,:Debit,:IsInterest])
Account()::Account = Account(Currency(:USD), 1e6, init_ledger())
Account(currency::Currency)::Account = Account(currency, 1e6, init_ledger())
Account(currency::Currency, balance::Real)::Account = Account(currency, balance, init_ledger())
function show(io::IO, acct::Account)
    println(io, "Account Balance: $(acct.balance) $(acct.currency.asset_id)")
    if (!isempty(acct.ledger))
        println(io, "Credits/Debits:")
        show(io, acct.ledger)
    else
        println(io, "No Credits/Debits Recorded.")
    end
end

# ==== ORDERS ====
abstract Order

#TODO: other order types (limit, stop, etc)
type MarketOrder
    timestamp::TimeType
    asset::Asset
    qty::Real
    filled::Real  # could either be pct filled or 1/0 to denote complete order
    qty_remaining::Real
    avg_price::Real
    value::Real
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

type Transaction
    asset::Asset
    qty::Real
    price::Real
    value::Real
    fees::Real
end

type Blotter
    timestamp::TimeType
    qty::Vector{Real}
    filled::Bool
    qty_remaining::Vector{Real}
    avg_fill_price::Vector{Float64}
    price_start::Vector{Float64}
    price_final::Vector{Float64}
end
