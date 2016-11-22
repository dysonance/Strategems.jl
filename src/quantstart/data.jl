#=
Implementation of the Quantstrat event-driven backtester's data handling methods.

See here: https://www.quantstart.com/articles/Event-Driven-Backtesting-with-Python-Part-III
=#

# using Base.Dates
# include("event.jl")
using Temporal

@doc """
DataHandler is an abstract type providing the interface for all inherited data handling protocols (both live and historic).

The goal of a (derived) DataHandler object is to output a generated set of bars (OHLCV) for each symbol requested.

This will replicate how a live strategy would function as current market data would be sent 'down the pipe'.

Thus a historic and live system will be treated identically by the rest of the backtesting framework.
""" ->
abstract DataHandler

@doc """
HistoricYahooDataHandler is designed to download price data from Yahoo for each requested symbol and provide an interfrace to obtain the 'latest' bar in a manner identical to a live trading interface.
""" ->
type HistoricYahooDataHandler <: DataHandler
    events::EventQueue  #TODO: implement EventQueue
    tickers::Vector{String}  # list of ticker symbols to fetch
    pricedata::Dict{String,TS}  # Dict holding time series of all price data, indexed by ticker
    lastprices::Dict{String,TS}  # Dict holding most recent prices, indexed by ticker
    continue_backtest::Bool  # whether to continue with the backtest
end

@doc """
get_data_yahoo downloads historical Yahoo Finance stock prices for each ticker, assigns them to the given DataHandler, and sets the lastprices field to an empty TS object.
""" ->
function get_data_yahoo!(dh::HistoricYahooDataHandler)
    t = Date[]
    @inbounds for ticker in dh.tickers
        dh.pricedata[ticker] = Temporal.yahoo(ticker)
        dh.lastprices[ticker] = ts()  # set to empty TS object
        t = union(t, dh.pricedata[ticker].index)
    end
    #TODO: implement reindex method in Temporal package to make this easier
    dummydata = ts(zeros(length(t)), t, :Dummy)
    @inbounds for ticker in dh.tickers
        dh.pricedata[ticker] = [dummydata dh.pricdata[ticker]][:,2:end]
    end
end

@doc """
get_new_bar returns the latest bar from the data feed as a Tuple of (ticker, date/time, open, high, low, close, volume).
""" ->
function get_new_bar(dh::DataHandler, ticker::String)
    state = start(dh[ticker])
    while !done(dh[ticker], state)
        (bar, state) = next(X, state)
        produce(ticker, bar[1], tuple(bar[2]...)...)
    end
end
# Construct a generator that generates a new Task for each ticker in the universe
getnewbars = ((@task get_new_bar(dh, ticker)) for ticker in tickers)
# Example usage (runs through each price observaton of each asset)
# for task in getnewbars
#     for t in task
#         println(t)
#     end
# end

@doc doc"""
get_latest_bars(dh::DataHandler, ticker::String, n::Int=1)
Returns the last `n` bars from the latest_symbol list, or n-k if less available.
""" ->
function get_latest_bars(dh::DataHandler, ticker::String, n::Int=1)
    try
        bars_list = dh.lastprices[ticker]
    catch KeyError
        println("That ticker symbol is not available in the historical data set.")
    end
    return bars_list[end-n+1:end]
end

@doc doc"""
update_bars(dh::DataHandler)
Pushes the latest bar to the lastprices structure for all ticker symbols.
""" ->
function update_bars(dh::DataHandler)
    @inbounds for ticker in dh.tickers
        try
            bar = get_new_bar(dh, ticker).next()  #TODO: ensure this is a generator
        catch
            dh.continue_backtest = false
        finally
            if bar != Void
                append!(dh.lastprices[ticker], bar)
            end
        end
    end
    append!(dh.events, MarketEvent())
end
