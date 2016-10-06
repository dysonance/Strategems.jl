# DATA #########################################################################
tickers = ["XLY","XLP","XLE","XLF","XLV","XLI","XLB","XLK","XLU"]
universe = Dict()
for t in tickers
    print("Downloading data for $t...")
    universe[t] = yahoo(t)
    print("Done.\n")
end

calcs = Dict{Symbol,Calc}()
calcs[:ShortMA] = Calc(ema, [:AdjClose], :(n=40), 20:5:80)
calcs[:LongMA] = Calc(sma, [:AdjClose], :(n=200), 100:20:300)

sigs = Dict{Symbol,Calc}()
sigs[:Long] = Signal(:ShortMA, >, :LongMA)
sigs[:Short] = Signal(:ShortMA, <, :LongMA)
sigs[:Exit] = Signal(:ShortMA, ==, :LongMA)

strat = Strategy(universe, calcs, sigs)
