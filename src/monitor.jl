using PyCall, Printf

# TODO:
# add function store_ref that saves the current prices
# add function read_ref that reads the reference prices

bi = pyimport("python_bitvavo_api.bitvavo")

MARKETS= ["BTC-EUR","CHR-EUR","ETH-EUR", "HNT-EUR", "JST-EUR", "LTO-EUR"]
PRICES = [57489, 1.1399, 4111, 44.465, 0.079123, 0.6538]
LAST_TIME = Int(round(time())) - 60

ref="""BTC-EUR,CHR-EUR,ETH-EUR,HNT-EUR,JST-EUR,LTO-EUR
       57489,  1.1399, 4111,   44.465,0.079123,0.6538"""

SETTINGS = Dict("APIKEY"      => ENV["APIKEY"], 
                "APISECRET"   => ENV["APISECRET"], 
                "RESTURL"     => "https://api.bitvavo.com/v2",
                "WSURL"       => "wss://ws.bitvavo.com/v2/",
                "ACCESSWINDOW"=> 10000,
                "DEBUGGING"   => false )

BITVAVO =  bi.Bitvavo(SETTINGS)

function fetch_markets(bitvavo)
    markets = []
    res = bitvavo.tickerPrice(Dict())
    for i in 1:length(res)
        market = res[i]["market"]
        if occursin("EUR", market)
            push!(markets, market)
        end
    end
    return markets
end

function write_header(logfile, markets)
    j = 1
    open(logfile, "w") do file
        for market in markets
            if j > 1
                write(file, ",")
            else
                write(file, "TIME,")
            end
            write(file, market)
            j += 1
        end
        write(file, "\n")
    end
end

function query(bitvavo, logfile, markets)
    global LAST_TIME
    prices = zeros(length(MARKETS))
    all_prices = zeros(length(markets))
    res = bitvavo.tickerPrice(Dict())
    j = 1
    k = 1
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
        if market in markets
            price = parse(Float64, res[i]["price"])
            all_prices[k] = price
            k += 1
        end
    end
    println()
    # create a log file entry once per minute
    now = Int(round(time()))
    if now > LAST_TIME + 60
        j = 1
        open(logfile, "a") do file
            for market in markets
                if j == 1
                    write(file, string(Int(round(time()))))
                end
                write(file, ",")
                price = all_prices[j]
                write(file, string(price))
                j += 1
            end
            write(file, "\n")
        end
        LAST_TIME = now
    end
end

function main()
    Base.exit_on_sigint(false)
    markets = fetch_markets(BITVAVO)
    try
        j = 1
        logfile = "data/log_" * string(Int(round(time()))) * ".csv"
        write_header(logfile, markets)
        while true   
            query(BITVAVO, logfile, markets)
            sleep(5) 
        end
    catch InterruptException
        @info "Interrupt captured!"
    end
end

# main
main()

nothing