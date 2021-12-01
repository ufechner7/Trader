using Plots
using Statistics 
using Flux
using FeatureTransforms

include("create_training_data.jl")
db = load_training_db()

# Auxiliary functions for generating our data
function generate_real_data(n)
    x1 = rand(1,n) .- 0.5
    x2 = (x1 .* x1)*3 .+ randn(1,n)*0.1
    return vcat(x1,x2)
end

function generate_real_data2(db, n)
    view = filter(:BUY => ==(true), db)
    x1 = view.RISE_1h[1:n]
    x2 = view.RISE_24h[1:n]
    return vcat(x1', x2')
end

function generate_fake_data2(db, n)
    view = filter(:BUY => ==(false), db)
    x1 = view.RISE_1h[1:n]
    x2 = view.RISE_24h[1:n]
    return vcat(x1', x2')
end

function read_data(db, n)
    view = filter(:BUY => ==(true), db)
    rd1 = view.RISE_1h[1:n]
    rd2 = view.RISE_24h[1:n]
    rd = vcat(rd1', rd2')
    view = filter(:BUY => ==(false), db)
    fd1 = view.RISE_1h[1:n]
    fd2 = view.RISE_24h[1:n]
    fd = vcat(fd1', fd2')
    data_1h = vcat(rd1', fd1')
    data_24h = vcat(rd2', fd2')
    scaling_1h = MeanStdScaling(data_1h)
    scaling_24h = MeanStdScaling(data_24h)
    FeatureTransforms.apply!(data_1h, scaling_1h)
    FeatureTransforms.apply!(data_24h, scaling_24h)
    rd = vcat(data_1h[1,:]', data_24h[1,:]')
    fd = vcat(data_1h[2,:]', data_24h[2,:]')
    rd, fd, scaling_1h, scaling_24h
end

function generate_fake_data(n)
    θ  = 2*π*rand(1,n)
    r  = rand(1,n)/3
    x1 = @. r*cos(θ)
    x2 = @. r*sin(θ)+0.5
    return vcat(x1,x2)
end

# Creating our data
train_size = 5000
real = generate_real_data(train_size)
fake = generate_fake_data(train_size)

# Visualizing
scatter(real[1,1:500],real[2,1:500])
scatter!(fake[1,1:500],fake[2,1:500])

function NeuralNetwork()
    Chain(
        Dense(2, 25, relu),
        Dense(25, 1, x->σ.(x))
    )
end

# Organizing the data in batches
X    = hcat(real, fake)
Y    = vcat(ones(train_size), zeros(train_size))
data = Flux.Data.DataLoader((X, Y'), batchsize=100, shuffle=true)

# Defining our model, optimization algorithm and loss function
m    = NeuralNetwork()
opt  = Descent(0.05)
loss(x, y) = sum(Flux.Losses.binarycrossentropy(m(x), y))

# Organizing the data in batches
X    = hcat(real, fake)
Y    = vcat(ones(train_size), zeros(train_size))
data = Flux.Data.DataLoader((X, Y'), batchsize=100, shuffle=true)

# Training
ps = Flux.params(m)
epochs = 20
for i in 1:epochs
    Flux.train!(loss, ps, data, opt)
end
println(mean(m(real)), " ", mean(m(fake))) # print model prediction

scatter( real[1, 1:100], real[2, 1:100], zcolor=m(real)')
scatter!(fake[1, 1:100], fake[2, 1:100], zcolor=m(fake)', legend=false)