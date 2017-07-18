using Temporal, Indicators

immutable struct Strategy
    acct::Account
    portfolio::Portfolio
    blotter::Blotter
    indicators::Vector{Indicator}
    signals::Vector{Signal}
    rules::Vector{Rule}
end
