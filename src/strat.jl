using Temporal, Indicators

immutable struct Strategy
    acct::Account
    portfolio::Portfolio
    blotter::Blotter
    indicators::Function  # function to put all indicators in same TS
    signals::Function  # function to calculate signals from data
    rules::Function  # function to generate orders from signals
end
