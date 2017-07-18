using Base.Dates
#=
Adapted from the QuantStart tutorial on developing event-driven backtesting systems.

See here: https://www.quantstart.com/articles/Event-Driven-Backtesting-with-Python-Part-II
=#


@doc """
Event is an abstract type providing the framework for all inherited event types.
""" ->
abstract Event


@doc """
MarketEvent handles the reception of new market data updates.
""" ->
type MarketEvent
end


@doc """
SignalEvent handles the event of sending a Signal from a Strategy object, which is then received by the Portfolio for the triggering of some action.
""" ->
type SignalEvent
    symbol::String  # ticker symbol the signal event applies to
    timing::TimeType  # timestamp at which the signal was generated
    sigtype::Symbol  # :LONG, :SHORT, or :EXIT
    function SignalEvent(symbol::String, timing::TimeType, sigtype::Symbol)
        new(symbol, timing, sigtype)
    end
end


@doc """
OrderEvent handles the event of sending an Order to an execution system given a ticker, type, quantity, and direction.
""" ->
type OrderEvent
    ticker::String  # ticker symbol the order is for
    order::Symbol  # :MKT for market orders, :LIM for limit orders, :STOP for stop orders
    qty::Int  # non-negative integer for quantity
    dir::Symbol  # :BUY for long, :SELL for short
    function OrderEvent(ticker::String, order::Symbol, qty::Real, dir::Symbol)
        @assert dir == :BUY || dir == :SELL  #TODO: come back to this
        @assert order == :Market || order == :Limit || order == :Stop  #TODO: come back to this
        @assert qty >= 0  #TODO: ensure must be positive, i.e. neg vals dont mean shorting
        new(ticker, order, qty, dir)
    end
end
function print_order(order::OrderEvent)
    println("Order: Ticker=$(order.ticker), Type=$(order.order), Quantity=$(order.qty), Direction=$(order.dir)")
end


@doc """
FillEvent encapsulates the notion of a Filled Order as returned from a brokerage.

Stores the quantity of an instrument actually filled and at what price and stores the commission of the trade from the brokerage.
""" ->
type FillEvent
    ticker::String  # ticker symbol of asset on the order
    time::TimeType  # date/time of when the order was filled
    exch::String  # exchange on which order was filled
    qty::Real  # number of units traded
    dir::Symbol  # direction of the fill (:BUY or :SELL)
    cost::Real  # optional commission sent from broker
    function FillEvent(ticker::String, time::TimeType, exch::String, qty::Real, dir::Symbol, cost::Real=0.0)
        @assert cost >= 0.0
        @assert dir == :BUY || dir == :SELL
        @assert qty >= 0.0
        if cost == 0.0
            # Default cost structure from Interactive Brokers for equities
            fullcost = 1.3
            if qty <= 500
                cost = max(fullcost, 0.013*qty)
            else
                cost = max(fullcost, 0.008*qty)
            end
            cost = min(full_cost, 0.5/100.0 * qty * cost)
        end
        new(ticker, time, exch, qty, dir, cost)
    end
end
