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
1. create new data frame with the colums
time active_markets_array

2. plot the relative courses for each of these arrays

3. investigate why we loose money

1. add plot of course and rating of one market
3. add rel_price to the bookings table; relative to t=0 when buying first, relative to buying when selling, relative to selling when buying second 
   perhaps we should not buy when rel_price is smaller than -5% and only sell when rel_price is smaller than -5%
4. add NLOpt to optimizer parameters like min_rating
5. plot portefeuille !!!
6. implement function analyze_portefeuille()
   - create a table that lists all our coins and their performance
   - create an optimal portefeuille
   - compare them
   - make suggestions what to sell and what to buy now
   - make suggestions what to sell and what to buy later

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