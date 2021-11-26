# Global constants

# scalar constants
const START_KAPITAL = 1000.0           # in EUR
const MAX_TRADE     = 140.0            # max EUR per trade when buying
const FEE           = 1.0 - 0.45/100.0 # 0.45% fee per trade (0.25 fee, 0.2% spread)
const MAX_RISE      =  4.3             # buy  if RISE_1h goes above this value [%]
const MIN_DROP      = -25.0            # sell if DROP_1h goes below this value [%]
const MIN_DROP_24   = -35.0            # sell if DROP_24h goes below this value [%]
const WAIT          = 60               # number of minutes to wait before dealing
const DAYS          = 4                # number of days to wait for valid rating
const MIN_RATING    = 70               # minimal rating to buy a coin

# array constants
# PREFER   = String["AVAX_EUR", "SAND_EUR","VGX_EUR"]
const PREFER = String[]