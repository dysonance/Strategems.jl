# 1. Calculate indicators
# 2. Compute signals
# 3. Translate signals to orders
# 4. Submit orders to blotter account/portfolio management framework
#   (a) Update portfolio
#   (b) Update account
# 5. Repeat for all periods where market data available

# ==== DATA ====
symbols = [:CL1, :RB1, :C1]
Universe = Dict{Symbol,TS}()
idx = Date(0):Day(1):today()
for sym in symbols
    println(sym)
    tmp = quandl("CHRIS/CME_$(string(sym))")
    idx = intersect(idx, tmp.index)
    Universe[sym] = tmp
end
from = minimum(idx)
thru = maximum(idx)
for sym in symbols
    Universe[sym] = Universe[sym][idx]
end

# ==== CALCS ====
function get_fun(calc)::Function
    fun::Symbol = calc.args[1]
    tgt = calc.args[2]
    params::Vector{Expr} = calc.args[3:end]
    arg_str::String = join(string.(params), ',')
    # s::String = "$(calc.args[1])($(calc.args[2]), $(calc.args[3]))"
    s::String = "$(fun)($(tgt), $(arg_str))"
#TODO: handle indicators where last row could be a vector
    f::Expr = parse("fun(X)::Float64 = try return $(s)[end]; catch return NaN; end")
    return eval(f)
end

calc = :(ema(cl(X).values, n=200, wilder=false))
fun = get_fun(calc)

n = length(idx)
k = length(symbols)
order_queue = zeros(k)
holdings = ts(zeros((n,k)), idx, symbols)
trade_px = ts(zeros((n,k)), idx, symbols)
close_px = ts(zeros((n,k)), idx, symbols)
Calcs = ts(zeros((n,k)), idx, symbols)

#TODO: performing tuning!
@inbounds for i in 2:n
    println(idx[i])
    @inbounds for sym in symbols
        # extract data
        X = Universe[sym][1:i]
        j = findfirst(symbols.==sym)
        # fill orders at open
        holdings.values[i,j] = order_queue[j] + holdings.values[i-1,j]
        trade_px.values[i,j] = op(X).values[i]
        order_queue[j] = 0.0
        close_px.values[i,j] = cl(X).values[i]
        # calculate indicators as of latest data
        Calcs[sym].values[1:i] = fun(X)
        # trading logic
        if X.values[i,j] > Calcs.values[i,j] && X.values[i-1,j] <= Calcs.values[i-1,j]
            order_queue[j] = -holdings.values[i,j] + 10  # long 10 lots
        elseif X.values[i,j] < Calcs.values[i,j] && X.values[i-1,j] >= Calcs.values[i-1,j]
            order_queue[j] = -holdings.values[i,j] -10  # short 10 lots
        else
            order_queue[j] = 0  # hold position
        end
    end
end
