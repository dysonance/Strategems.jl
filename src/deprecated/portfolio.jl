mutable struct Portfolio
    assets::Vector{Asset}
    holdings::TS{Real}  # columns are assets, rows are holdings
    values::TS{Real}  # columns are assets, rows are position values
    weights::TS{Real}  # columns are assets, rows are portfolio weights
end
function init_holdings(assets::Vector{Asset})::TS
    n_assets = length(assets)
    ids = Vector{Symbol}(n_assets)
    @inbounds for i in 1:n_assets
        ids[i] = assets[i].asset_id
    end
    holdings = ts(zeros(0,n_assets), Vector{Date}(), ids)
    return holdings
end


