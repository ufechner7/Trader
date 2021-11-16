using HTTP, JSON, JSON3

const URL     = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest"
const PARAMS  = Dict("start" => "1", "limit" => "5000", "convert" => "USD")

function make_API_call(url, params)
    try
        response = HTTP.get(url, ["Accepts" => "application/json", "X-CMC_PRO_API_KEY" => ENV["CMC_PRO_API_KEY"]], JSON.json(params))
        return String(response.body)
    catch e
        return "Error occurred : $e"
    end
end

response = make_API_call(URL, PARAMS)
res=JSON3.read(response)
res.data[1].quote.USD

