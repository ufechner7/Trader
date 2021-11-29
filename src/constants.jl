# Global constants

# scalar constants
const START_KAPITAL = 1000.0           # in EUR
const MAX_TRADE     = 140.0            # max EUR per trade when buying
KEEP                = 140.0            # min EUR to keep as cash
const FEE           = 1.0 - 0.45/100.0 # 0.45% fee per trade (0.25 fee, 0.2% spread)
const MAX_RISE      =  4.4             # buy  if RISE_1h goes above this value [%]
const MIN_DROP      = -25.0            # sell if DROP_1h goes below this value [%]
const MIN_DROP_24   = -35.0            # sell if DROP_24h goes below this value [%]
const DAYS          = 4                # number of days to wait for valid rating
MIN_RATING          = 20               # minimal rating to buy a coin; 
MAX_RATING          = 0.75*MIN_RATING  # maximal rating to sell a coin
EXTRA_RATING        = 10.0             # extra rating for fast rise
DECAY               = 60               # time constant for decay of extra rating
INTERVAL            = 6                # intervall between evaluations in hours
STOP_LIMIT          = 0.96             # if total drops below STOP_LIMIT * maximum, then STOP

# array constants
PREFER = String[]