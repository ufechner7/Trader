# Monitor and trading crypto coins

## Links
https://docs.bitvavo.com/

https://www.simplilearn.com/tutorials/machine-learning-tutorial/stock-price-prediction-using-machine-learning#stock_price_prediction

https://machinelearningmastery.com/stacked-long-short-term-memory-networks/

https://discourse.julialang.org/t/simple-flux-lstm-for-time-series/35494/22

https://medium.com/datathings/recurrent-lstm-layers-explained-in-a-simple-way-d615ebcac450

https://sdobber.github.io/FA_LSTNet/

## Installation
    use PyCall
    use Conda
    Conda.pip_interop(true)
    Conda.pip("install", "python-bitvavo-api")

### TODO
1. create Bitbucket repo

### DONE
1. write a script that monitors the price of n coins once per 5s

### Rules
1. - determine highest price in last month
   - sell if an asset falls below 90% of that value