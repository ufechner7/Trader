using CSV, DataFrames, FluxArchitectures, Plots
dataset_train = CSV.read("data/Google_Stock_Price_Train.csv", DataFrame)
training_set = Vector{Float32}(dataset_train.Open)

data = reshape(training_set, (size(training_set)..., 1))
poollength = 10
datalength = size(training_set)[1] - poollength + 1 # output data length
horizon = 15
input, target = prepare_data(data, poollength, datalength, horizon; normalise=true)

@info "Creating model and loss"
inputsize = size(input, 1)
convlayersize = 2
recurlayersize = 3
skiplength = 240
model = LSTnet(inputsize, convlayersize, recurlayersize, poollength, skiplength, init=Flux.zeros32, initW=Flux.zeros32)

function loss(x, y)
    Flux.reset!(model)
    return Flux.mse(model(x), y')
end

cb = function ()
    Flux.reset!(model)
    pred = model(input)' |> cpu
    Flux.reset!(model)
    p1 = plot(pred, label="Predict")
    p1 = plot!(cpu(target), label="Data", title="Loss $(loss(input, target))")
    display(plot(p1))
end

@info "Start loss" loss = loss(input, target)
@info "Starting training"
Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 60), ADAM(0.02), cb=cb)
Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 80), ADAM(0.01), cb=cb)
@info "Final loss" loss = loss(input, target)
