#=
methods for handling backtest results of strategy objects
=#

mutable struct Results
    trades::Dict{String,TS}
    backtest::Dict{String,TS{Float64}}
    optimization::Matrix{Float64}
    function Results(trades::Dict{String,TS}=Dict{String,TS}(),
                     backtest::Dict{String,TS{Float64}}=Dict{String,TS{Float64}}(),
                     optimization::Matrix{Float64}=Matrix{Float64}(undef,0,0))
        return new(trades, backtest, optimization)
    end
end


