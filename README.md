# Monitor and trading crypto coins

## Links
https://docs.bitvavo.com/

https://www.simplilearn.com/tutorials/machine-learning-tutorial/stock-price-prediction-using-machine-learning#stock_price_prediction

https://machinelearningmastery.com/stacked-long-short-term-memory-networks/

https://discourse.julialang.org/t/simple-flux-lstm-for-time-series/35494/22

https://medium.com/datathings/recurrent-lstm-layers-explained-in-a-simple-way-d615ebcac450

https://sdobber.github.io/FA_LSTNet/

## Installation
    using PyCall
    using Conda
    Conda.pip_interop(true)
    Conda.pip("install", "python-bitvavo-api")

### TODO
1. improve simulated auto-trading
   - add plotting of all coins
2. plot bitcoin dataset in julia
3. re-write bitcoin predictor in Julia

### DONE
1. write a script that monitors the price of n coins once per 5s
2. create Bitbucket repo
3. follow tutorial on prediction
4. implement recording of market data
5. add script analyze.jl
6. interpolate missing values
7. create trade database; colums: time, market, sell_eur, buy_eur, sell_coins, buy_coins, save_eur, withdraw_eur, total

### Rules
1. - determine highest price in last month
   - sell if an asset falls below 90% of that value