using FluxArchitectures, Plots

@info "Loading data"
poollength = 10
horizon = 15
datalength = 1000
input, target = get_data(:exchange_rate, poollength, datalength, horizon)

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
Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 150), ADAM(0.02), cb=cb)
Flux.train!(loss, Flux.params(model),Iterators.repeated((input, target), 200), ADAM(0.01), cb=cb)
@info "Final loss" loss = loss(input, target)
