#=
Implementation of the QuantStart event-driven backtester's portfolio methods.

See here: https://www.quantstart.com/articles/Event-Driven-Backtesting-with-Python-Part-v
=#

using Temporal

@doc """
The Portfolio type handles the positions and market value of all instruments at a resolution of a 'bar'.
""" ->
abstract Portfolio

@doc doc"""
update_signal(port::Portfolio)

Acts on a SignalEvent to generate new orders based on the portfolio logic.
""" ->
function update_signal(port::Portfolio)
    error("Must implement the update_signal function.")
end

@doc """
The NaivePortfolio object is designed to send orders to a brokerage object with a constant quantity size blindly (without any risk management or position sizing). It is used to test simpler strategies such as BuyAndHoldStrategy.
""" ->
type NaivePortfolio <: Portfolio
    bars::DataHandler
    events::EventQueue
    fromdate::TimeType
    initeqty::Number
    tickers::Vector{String}
    all_positions::Vector{Dict{String,Number}}
    cur_positions::Dict{String,Number}
    all_holdings::Vector{Dict{String,Number}}
    cur_holdings::Dict{String,Number}
    function NaivePortfolio(bars::DataHandler, events::EventQueue, fromdate::TimeType, initeqty::Number=100_000.0)
        tickers = bars.tickers
        all_positions = [Dict{String,Any}(ticker=>0 for ticker in tickers)]
        all_positions[1]["DateTime"] = fromdate
        cur_positions = all_positions[1]
        all_holdings = [Dict{String,Any}(ticker=>0 for ticker in tickers)]
        all_holdings[1]["DateTime"] = fromdate
        all_holdings[1]["Cash"] = initeqty
        all_holdings[1]["Total"] = initeqty
        all_holdings[1]["Commission"] = 0.0
        cur_holdings = all_holdings[1]
        new(bars, events, fromdate, initeqty, tickers, all_positions, cur_positions, all_holdings, cur_holdings)
    end
end

@doc doc"""
update_timeindex!(port::NaivePortfolio, event::Event)

Adds a new record to the positions matrix for the current market data bar, reflecting the PREVIOUS bar (all current market data at this stage is known). Makes use of a MarketEvent from the events queue.
""" ->
function update_timeindex!(port::NaivePortfolio, event::Event)
    bars = Dict()
    for ticker in port.tickers
        bars[ticker] = get_latest_bars(port.bars, ticker, 1)
    end
    # Update positions
    dp = Dict{String,Any}(ticker=>0 for ticker in port.tickers)
    dp["DateTime"] = bars[port.tickers[1]][1][2]
    for ticker in port.tickers
        dp[ticker] = port.cur_positions[ticker]
    end
    # Append the current positions
    append!(port.all_positions, dp)
    # Update holdings
    dh = Dict{String,Any}(ticker=>0 for ticker in port.tickers)
    dh["DateTime"] = bars[port.tickers[1]][1][2]
    dh["Cash"] = port.current_holdings["Cash"]
    dh["Commission"] = port.current_holdings["Commission"]
    dh["Total"] = port.current_holdings["Total"]
    for ticker in port.tickers
        # Approximation to the real value
        mktval = port.cur_positions[ticker] * bars[ticker][1][4]
        dh[ticker] = mktval
        dh["Total"] += mktval
    end
    # Append the current holdings
    append!(port.all_holdings, dh)
    nothing
end

@doc doc"""
update_positions_from_fill!(port::NaivePortfolio, fill::FillEvent)

Takes a FillEvent object and updates the position matrix to reflect the new position.
""" ->
function update_positions_from_fill!(port::NaivePortfolio, fill::FillEvent)
    # Check whether the fill is a buy or sell
    fill_dir = 0
    if fill.dir == :BUY
        fill_dir = 1
    elseif fill.dir == :SELL
        fill_dir = -1
    end
    # Update positions list with new quantities
    port.cur_positions[fill.ticker] += fill_dir*fill.qty
    nothing
end

@doc doc"""
update_holdings_from_fill!(port::NaivePortfolio, fill::FillEvent)

Takes a FillEvent object and updates the holdings matrix to reflect the holdings value.
""" ->
function update_holdings_from_fill!(port::NaivePortfolio, fill::FillEvent)
    # Check whether the fill is a buy or sell
    fill_dir = 0
    if fill.dir == :BUY
        fill_dir = 1
    elseif fill.dir == :SELL
        fill_dir = -1
    end
    # Update holdings list with new quantities
    fill_cost = get_latest_bars(port.bars, fill.ticker)[1][4]  # close price
    cost = fill_dir * fill_cost * fill.qty
    port.cur_holdings[fill.ticker] += cost
    port.cur_holdings["Commission"] += fill.commission
    port.cur_holdings["Cash"] -= (cost + fill.commission)
    port.cur_holdings["Total"] -= (cost + fill.commission)
    nothing
end

@doc doc"""
update_fill(port::Portfolio)

Updates the portfolio current positions and holdings from a FillEvent.
""" ->
function update_fill(port::NaivePortfolio, fill::FillEvent)
    update_positions_from_fill!(port, fill)
    update_holdings_from_fill!(port, fill)
end

@doc doc"""
generate_naive_order(port::NaivePortfolio, signal::SignalEvent)

Simply transacts an OrderEvent object as a constant quantity sizing of the signal object, without risk management or position sizing considerations.
""" ->
function generate_naive_order(port::NaivePortfolio, signal::SignalEvent)
    strength = 1  # original: strength = signal.strength (missing strength field from SignalEvent typedef)
    mktqty = floor(100*strength)
    curqty = port.cur_positions[signal.ticker]
    ordertype = :MKT  #TODO: generalize to other order types and take from a parameter

    if signal.sigtype == :LONG && curqty == 0:
        order = OrderEvent(ticker, ordertype, mktqty, :BUY)
    elseif signal.sigtype == :SHORT && curqty == 0:
        order = OrderEvent(ticker, ordertype, mkqty, :SELL)
    end

    if signal.sigtype == :EXIT and curqty > 0:
        order = OrderEvent(ticker, ordertype, abs(curqty), :SELL)
    elseif signal.sigtype == :EXIT and curqty < 0:
        order = OrderEvent(ticker, ordertype, abs(curqty), :BUY)
    end

    return order
end

@doc doc"""
update_signal!(port::NaivePortfolio, signal::SignalEvent)

Acts on a SignalEvent to generate new orders based on the portfolio logic and add them to the event queue.
""" ->
function update_signal!(port::NaivePortfolio, signal::SignalEvent)
    append!(port.events, generate_naive_order(port, signal))
end

@doc doc"""
create_equity_curve(port::NaivePortfolio)

Generates a normalized equity curve (percentage-based) or returns stream for performance calculations.
""" ->
function create_equity_curve(port::NaivePortfolio)
    index = [d["DateTime"] for d in port.all_holdings]  # collect dates from all holdings vector
    portvals = [d["Total"] for d in port.all_holdings]  # collect portfolio total values from all holdings vector
    bar_rets = (portvals[2:end] ./ portvals[1:end-1]) - 1.0  # compute returns by bar
    cum_rets = [1.0; cumprod(1.0+bar_rets)]  # compute cumulative returns
    return Temporal.TS(cum_rets, index, [:CumRets])
end
