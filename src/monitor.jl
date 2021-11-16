using PyCall, Printf

bi = pyimport("python_bitvavo_api.bitvavo")

MARKETS= ["BTC-EUR","CHR-EUR","ETH-EUR", "HNT-EUR", "JST-EUR", "LTO-EUR"]
PRICES = [57489, 1.1399, 4111, 44.465, 0.079123, 0.6538]

ref="""BTC-EUR,CHR-EUR,ETH-EUR,HNT-EUR,JST-EUR,LTO-EUR
       57489,  1.1399, 4111,   44.465,0.079123,0.6538"""

SETTINGS = Dict("APIKEY"      => ENV["APIKEY"], 
                "APISECRET"   => ENV["APISECRET"], 
                "RESTURL"     => "https://api.bitvavo.com/v2",
                "WSURL"       => "wss://ws.bitvavo.com/v2/",
                "ACCESSWINDOW"=> 10000,
                "DEBUGGING"   => false )

bitvavo =  bi.Bitvavo(SETTINGS)

Base.exit_on_sigint(false)
try
    while true   
        res = bitvavo.tickerPrice(Dict())
        j = 1
        for i in 1:length(res)
            market = res[i]["market"]
            if market in MARKETS
                price = parse(Float64, res[i]["price"])
                rel_price = price/PRICES[j]*100.0
                print(res[i]["market"] * ": " * lpad(res[i]["price"], 8) * ", rel_price: ")
                @printf "%7.2f %%\n" rel_price
                j += 1
            end
        end
        println()
        sleep(5) 
    end
catch e
    @info "interrupt captured!"
end

nothing