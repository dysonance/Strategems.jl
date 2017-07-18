using Temporal, Indicators

# 0. initialize the accounting work (blotter, account, portfolio, orders)

# 1. define the universe of assets

# 2. define the indicators

# 3. define the signals
# go long when close crosses over 200-day sma, sell when it crosses under
sig_long = Signal(:(@cxo :AdjClose :SMA200), :Long)
sig_sell = Signal(:(@cxu :AdjClose :SMA200), :Sell)
sig_vec = [sig_long, sig_sell]

# 4. define the trading rules

