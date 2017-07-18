tickers = ["MSFT", "AAPL", "GOOG"]
getdata = false


if getdata
    universe = Dict{String,TS}()
    for ticker in tickers
        println(ticker)
        universe[ticker] = yahoo(ticker)
    end
end

X = universe["AAPL"]
function get_new_bar(universe, ticker)
    X = universe[ticker]
    state = start(X)
    while !done(X, state)
        (bar, state) = next(X, state)
        produce(ticker, bar[1], tuple(bar[2]...)...)
    end
end
getnewbars = ((@task get_new_bar(universe, ticker)) for ticker in tickers)
for task in getnewbars
    for t in task
        println(t)
    end
end
