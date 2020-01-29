# type and methods to track the evolution of a strategy's securities portfolio composition

mutable struct Portfolio
    txn::TS
    qty::TS
    wts::TS
    pnl::TS
    m2m::TS
    cap::TS
    function Portfolio(universe::Universe, initial_capital::Float64=1e6)
        index = get_overall_index(universe)
        columns = Symbol.(universe.assets)
        blanks = zeros(length(index), length(columns))
        txn = TS(blanks, index, columns)
        qty = TS(blanks, index, columns)
        wts = TS(blanks, index, columns)
        pnl = TS(blanks, index, columns)
        m2m = TS(blanks, index, columns)
        cap = TS(zeros(length(index)).+initial_capital, index, [:NAV])
        return new(txn, qty, wts, pnl, m2m, cap)
    end
end

#function update_portfolio!(portfolio::Portfolio, order::Order, universe::Universe)
#    i = findfirst(portfolio.idx .> order.time)
#    quantity[i]
#end
