using Temporal
using Base.Dates

include("$(Pkg.dir("Strategems"))/src/asset.jl")
universe = Dict{Symbol,Asset}()

curr = Currency(:USD)

tickers = [:AAPL, :GOOGL, :AMZN, :NFLX, :MSFT]
for ticker in tickers
    println(ticker)
    data = quandl("WIKI/$ticker")
    universe[ticker] = Equity(ticker, curr, 1.0, 0.01, data)
end

#TODO: incorporate Universe type into framework
#type Universe
#    ids::Vector{Symbol}
#    classes::Dict{Symbol,Asset}
#    data::Dict{Symbol,TS}
#    fromdate::Dates.TimeType
#    thrudate::Dates.TimeType
#end

fromdate = Date(0)
thrudate = today()
for ticker in tickers
    fromdate = max(fromdate, universe[ticker].data.index[1])
    thrudate = min(thrudate, universe[ticker].data.index[end])
end

for ticker in tickers
    universe[ticker].data = universe[ticker].data["$(fromdate)/$(thrudate)"]
end
