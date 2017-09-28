using Temporal, Indicators

immutable struct Strategy
    universe::Universe
    acct::Account
    portfolio::Portfolio
    blotter::Blotter
    indicators::Vector{Indicator}
    signals::Vector{Signal}
    rules::Vector{Rule}
end
