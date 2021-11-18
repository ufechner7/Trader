using PyCall, Printf

# TODO: 
# - generate unique log files
# - log the data

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

BITVAVO =  bi.Bitvavo(SETTINGS)

function query(bitvavo)
    prices = zeros(length(MARKETS))
    res = bitvavo.tickerPrice(Dict())
    j = 1
    for i in 1:length(res)
        market = res[i]["market"]
        if market in MARKETS
            price = parse(Float64, res[i]["price"])
            prices[j] = price
            rel_price = price/PRICES[j]*100.0
            print(res[i]["market"] * ": " * lpad(res[i]["price"], 8) * ", rel_price: ")
            @printf "%7.2f %%\n" rel_price
            j += 1
        end
    end
    println()
    j = 1
    for market in MARKETS
        if j == 1
            print(Int(round(time())))
        end
        print(",")
        price = prices[j]
        print(price)
        j += 1
    end
    println()
end


Base.exit_on_sigint(false)
try
    j = 1
    open("data/log.txt", "w") do file
        for market in MARKETS
            if j > 1
                write(file, ",")
            end
            write(file, market)
            j += 1
        end
        write(file, "\n")
    end
    while true   
        query(BITVAVO)
        sleep(5) 
    end
catch e
    @info "interrupt captured!"
end

nothing