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

            if list 
            println("==>2")
            new_list = list_markets(tdb)
            println(new_list)
            if new_list != old_list
                # println(last(view.TIME), " ", T0)
                # break
                time   = last(view.TIME) - T0
                time_h = time/3600.0
                println(round(time_h, digits=2)," ", new_list)
                old_list = new_list
            end
        

### TODO
1. add RATING to performance table
1. plot portefeuille !!!
2. implement function analyze_portefeuille()
   - create a table that lists all our coins and their performance
   - create an optimal portefeuille
   - compare them
   - make suggestions what to sell and what to buy now
   - make suggestions what to sell and what to buy later

2. improve simulated auto-trading
   - combine RISE_1h and RATING in one table; trigger only if RISE_1h > 4.2 AND RATING > 10.0
   - update RATING only once per hour
     buy only if DELTA > 0.0

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