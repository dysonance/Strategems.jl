using Strategems, Temporal, Indicators, Plots
using Dates
using Test

# define universe and gather data
assets = ["EOD/AAPL", "EOD/MCD", "EOD/JPM", "EOD/MMM", "EOD/XOM"]
universe = Universe(assets)

function datasource(asset::String; save_downloads::Bool=true)::TS
    path = joinpath(dirname(pathof(Strategems)), "..", "data", "test", "$asset.csv")
    if isfile(path)
        return Temporal.tsread(path)
    else
        X = quandl(asset)
        if save_downloads
            if !isdir(dirname(path))
                mkdir(dirname(path))
            end
            Temporal.tswrite(X, path)
        end
        return X
    end
end

gather!(universe, source=datasource)

# define indicator and parameters
function fun(x::TS; args...)::TS
    close_prices = cl(x)
    moving_average = sma(close_prices; args...)
    output = [close_prices moving_average]
    output.fields = [:Close, :MA]
    return output
end

# TODO: define method for when only one parameter is needed where it automatically puts things in vectors
# (so that you could call this by doing `ParameterSet(:n, 50)`)
indicator = Indicator(fun, ParameterSet([:n], [50]))

# define signals
longsignal = @signal Close ↑ MA
shortsignal = @signal Close ↓ MA

# define trading rules
longrule = @rule longsignal → buy 100
shortrule = @rule shortsignal → sell 100

# construct and test the strategy
strat = Strategy(universe, indicator, (longrule, shortrule))

backtest!(strat, px_trade=:Open, px_close=:Close)

weights, holdings, values, profits = summarize_results(strat)
# p1 = plot(cumsum(profits))
# p2 = plot(profits)
# p3 = plot(weights)
# plot(p1, p2, p3, layout=(3,1))
