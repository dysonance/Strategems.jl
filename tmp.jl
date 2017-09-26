# load dependencies
using Temporal, Indicators, Base.Dates
charts = false

# define backtest setup
from_date = today() - Year(10)
thru_date = today()
trade_qty = 10.0
initial_balance = 1e6
trade_field = :Open
close_field = :Settle

# define indicator parameters
ind_fun = Indicators.mama
ind_vals(x::TS) = hl2(x)
ind_args = (:fastlimit, 0.5,
            :slowlimit, 0.05)
ind_args_rng = (:fastlimit, 0.01:0.01:0.99,
                :slowlimit, 0.01:0.01:0.99)

# download historical data
X = quandl("CHRIS/CME_CL1", from=string(from_date), thru=string(thru_date))
ind_out = ind_fun(ind_vals(X); ind_args)

# initialize backtest variables
N = size(X,1)
go_long = crossover(ind_out[:MAMA].values, ind_out[:FAMA].values)
go_short = crossunder(ind_out[:MAMA].values, ind_out[:FAMA].values)
pnl = zeros(Float64, N)
pos = zeros(Float64, N)
in_price = NaN
trade_price = X[:,trade_field].values
close_price = X[:,close_field].values

# run trading logic for base case (default indicator args)
@inbounds for i in 2:N
    if go_long[i-1]
        pos[i] = trade_qty
        pnl[i] = pos[i] * (close_price[i] - trade_price[i])
    elseif go_short[i-1]
        pos[i] = -trade_qty
        pnl[i] = pos[i] * (close_price[i] - trade_price[i])
    else
        pos[i] = pos[i-1]
        pnl[i] = pos[i] * (close_price[i]-close_price[i-1])
    end
end
# summarize results from backtest
summary_ts = TS([Temporal.ohlc(X).values ind_out.values go_long go_short pos pnl cumsum(pnl)],
                X.index,
                vcat(Temporal.ohlc(X).fields, [:MAMA, :FAMA, :LongSignal, :ShortSignal, :Position, :PNL, :CumulativePNL]))

# visualize backtest results
using Plots
ℓ = @layout [ a; b{0.33h} ]
plotlyjs()
plot(plot(summary_ts[:,vcat(close_field,ind_out.fields)], color=[:black :magenta :green]),
     plot(summary_ts[:,end], color=:orange, fill=(0,:orange), fillalpha=0.5),
     layout = ℓ)


ps = ParameterSet([:fastlimit, :slowlimit], [0.5, 0.05])
ps.arg_ranges = [0.01:0.01:0.99, 0.01:0.01:0.99]
params = get_run_params(ps)

#TODO: make this more sophisticated
n_runs = get_n_runs(ps)
cum_pnl = zeros(Float64, n_runs)
@inbounds for j in 1:n_runs
    println("Iteration $j/$n_runs ($(j/n_runs*100)%)")
    ind_out = ind_fun(ind_vals(X); params[j]...)
    # initialize backtest variables
    N = size(X,1)
    go_long = crossover(ind_out[:MAMA].values, ind_out[:FAMA].values)
    go_short = crossunder(ind_out[:MAMA].values, ind_out[:FAMA].values)
    pnl = zeros(Float64, N)
    pos = zeros(Float64, N)
    in_price = NaN
    trade_price = X[:,trade_field].values
    close_price = X[:,close_field].values
    @inbounds for i in 2:N
        if go_long[i-1]
            pos[i] = trade_qty
            pnl[i] = pos[i] * (close_price[i] - trade_price[i])
        elseif go_short[i-1]
            pos[i] = -trade_qty
            pnl[i] = pos[i] * (close_price[i] - trade_price[i])
        else
            pos[i] = pos[i-1]
            pnl[i] = pos[i] * (close_price[i]-close_price[i-1])
        end
    end
    cum_pnl[j] = sum(pnl)
end
