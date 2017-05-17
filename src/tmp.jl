using Temporal, Indicators, Base.Dates

# ==== INPUTS ====
fromdate = "2014-05-04"
thrudate = string(today())
universe = ["CL1", "RB1", "NG1"]
lagcalcs = true

# ==== DATA ====
Universe = Dict{Symbol,TS}()
for asset in universe
    Universe[Symbol(asset)] = quandl("CHRIS/CME_$(String(asset))")
end

# ==== FILTERS ====


# ==== INDICATORS ====
Calcs = Dict{Symbol,TS}()
calcfun(X::TS)::TS = (m=[sma(cl(X),n=40) sma(cl(X),n=200)]; m.fields=[:SMA40,:SMA200]; return m)

for (key,val) in Universe
    Calcs[key] = calcfun(val)
end
if lagcalcs
    for (key,val) in Calcs
        Calcs[key] = lag(val)
    end
end

# ==== SIGNALS ====
Signals = Dict{Symbol,TS}()
sigfun(X::TS)::TS = (sig=[X[:SMA40]>X[:SMA200] X[:SMA40]<X[:SMA200]]; sig.fields=[:Long,:Short]; return sig)

for (key,val) in Calcs
    Signals[key] = sigfun(Calcs[key])
end

# ==== STRATEGIES ====
function init_blotter()::TS{Any,Date}
    B = ts{Any,Date}([:None 0], [Date(0)], [:Asset, :Quantity])
end
Blotter = init_blotter()

#TODO: allow quantities to be determined by the portfolio/account object
# (this probably means defining methods where the `q` argument is some type of expression or function
function order!(B, a::Symbol, q::Number, dt::Date)::Void
    # B = [B; ts([a q], [dt], [:Asset,:Quantity])]
    B.values = [B.values; [a q]]
    B.index = [B.index; dt]
    return nothing
end

function get_total_position(B, a::Symbol)::Number
    n = size(B, 1)
    A = Symbol.(B[:Asset].values)
    Q = Number.(B[:Quantity].values)
    q = 0
    @inbounds for i in 1:n
        if A[i] == a
            q += Q[i]
        end
    end
    return q
end

liquidate!(B, a::Symbol, dt::Date)::Void = order!(B, a, -get_total_position(B,a), dt)

function tradefun(sig::BitArray, a::Symbol, dt::Date)::Void
    if sig[1] && !sig[2]
        order!(Blotter, a, 100, dt)
    elseif !sig[1] && sig[2]
        order!(Blotter, a, -100, dt)
    else
        liquidate!(Blotter, a, dt)
    end
end

# iterate through all signal sets, and update trade blotter for each observation
#TODO: do this using generator syntax somehow
idx_mkt = Vector{Date}()  # initialize vector of all dates with market data observed
for (key,val) in Universe
    idx_mkt = unique(sort([idx_mkt; val.index]))
end

for dt in idx_mkt
    for (key,val) in Signals
        try
            sig = Bool.(val[dt].values)
            tradefun(sig, key, dt)
        end
    end
end
