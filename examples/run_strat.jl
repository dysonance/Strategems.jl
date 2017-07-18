using Temporal, Indicators

function indfun(universe::Dict{Symbol,Asset}, asset_id::Symbol)::TS{Float64}
    x = universe[asset_id].data[:AdjClose]
    y = sma(x, n=200)
    y.fields[1] = :SMA200
    return y
end

for (ticker, asset) in universe
    universe[ticker].data = [universe[ticker].data indfun(universe, ticker)]
end

function sigfun(universe::Dict{Symbol,Asset}, asset_id::Symbol)::TS{Bool}
    a = universe[id].data[[:AdjClose,:SMA200]]
    b = crossover(a[:AdjClose].values, a[:SMA200].values)
    c = crossunder(a[:AdjClose].values, a[:SMA200].values)
    return ts([b c], a.index, [:Long,:Sell])
end

signals = Dict{Symbol,TS}()
for (ticker, asset) in universe
    signals[ticker] = sigfun(universe, ticker)
end

# this is the function that generates the orders to be parsed later
function rulefun(signals::Dict{Symbol,Asset}, asset_id::Symbol, t::T)::Void where {T<:Dates.TimeType}
    s = signals[id]
    if s[t,:Long].values[1]
        order!(B, asset_id, 100, t)
    elseif s[t,:Sell].values[1]
        order!(B, asset_id, -100, t)
    end
end
