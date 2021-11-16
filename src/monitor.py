import os
from python_bitvavo_api.bitvavo import Bitvavo

bitvavo = Bitvavo({
  'APIKEY': os.environ['APIKEY'],
  'APISECRET': os.environ['APISECRET'],
  'RESTURL': 'https://api.bitvavo.com/v2',
  'WSURL': 'wss://ws.bitvavo.com/v2/',
  'ACCESSWINDOW': 10000,
  'DEBUGGING': False
})



response = bitvavo.time() 
print(response)

response = bitvavo.markets({})
print(response)
