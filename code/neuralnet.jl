using Flux
using Flux: LSTM, Dense, Chain, σ, ADAM, RNN, train!
using CSV
using ProgressMeter
using StatsBase
using DataFrames

function getdata(; trainingyears = 10,
    filename = "LTERwisconsinfish.csv",
    species = ["LARGEMOUTHBASS", "SMALLMOUTHBASS", "YELLOWPERCH", "PUMPKINSEED"])
    justfish = CSV.read(joinpath(".", filename), DataFrame)

    lakes = ["WEST LONG", "PAUL", "EAST LONG", "PETER"]
    years = unique(justfish[!, :year4])
    tensor = zeros((length(species), length(lakes), length(years)))

    # not good code 
    for (li, lake) in enumerate(lakes)
        for (si, sp) in enumerate(species)
            for (yi, year) in enumerate(years)
                hereandnow = filter(
                        [:species, :year4, :lakename] => 
                        (s,y, l) -> s == sp && y == year && l == lake, justfish
                    )
                if nrow(hereandnow) > 0 
                    tensor[si, li, yi] = 1
                end
            end
        end
    end

    @info "Using the first $trainingyears years of the total $(length(years)) as training data"

    training = tensor[:,:,begin:trainingyears]
    test = tensor[:,:,trainingyears+1:end]

    return training, test, species, lakes
end


using Flux
using Flux: onehot, chunk, batchseq, throttle, mse, params
using StatsBase: wsample
using Base.Iterators: partition
using Parameters: @with_kw

# Hyperparameter arguments 
@with_kw mutable struct Args
    lr::Float64 = 1e-2	# Learning rate
    seqlen::Int = 50	# Length of batchseqences
    nbatch::Int = 50	# number of batches text is divided into
    throttle::Int = 30	# Throttle timeout
end

# Function to construct model
function build_model(nf)
    return Chain(
            LSTM(nf, 32),
            LSTM(32, 32),
            Dense(32, 1))
end 

function getfeatures(tensor) 
    nspecies = size(tensor)[1]
    nlocations = size(tensor)[2]

    featuredims = size(tensor)[3] + 1

    features, labels = [], zeros(1, nspecies*nlocations)

    cursor = 1
    for s in 1:nspecies
        for l in 1:nlocations
            thisfeaturesvec = vec([s,l, tensor[s,l,1:end-1]...])
            thislabel = tensor[s,l,end]
  
            push!(features, thisfeaturesvec)
            labels[cursor] = thislabel
            cursor += 1
        end
    end

    return features, labels
end 

function loss(x, y)
    sum((Flux.stack(m.(x),1) .- y) .^ 2)
end

function train(;  
    n_batches = 50000, 
    batch_size = 10,
    mat_at = 500,
    opt = ADAM(),
    lossfunction = mse,
    kws...
)
    training, test, species, lakes = getdata(kws...)

    featureDims = 2 + size(training)[3]
    features, labels = getfeatures(training)
    # Constructing Model
    m = build_model(featureDims)
    
   
    ps = params(m)
    
    epc = mat_at:mat_at:n_batches
    epc = vcat(1, epc...)
    
    trainlossvalue = zeros(Float64, n_batches)
    testlossvalue = zeros(Float64, n_batches)


    # This is the main training loop
    @showprogress for i in 1:n_batches
        ord = sample(1:size(features)[1], batch_size; replace=false)   

        Xs = convert.(Array{Float32}, features[ord])
        Ys = Float32.(labels[ord])
        data_batch = zip(Xs,Ys)

        @show data_batch

        train!(loss, ps, data_batch, opt)
        
       
        # We only save the loss at the correct interval
        if i in epc
            trainlossvalue[i] = loss(data_batch...)
            testlossvalue[i] = loss(data_test...)
        end
    end
    return m
end

# Sampling
function sample(m, alphabet, len; seed="")
    m = cpu(m)
    Flux.reset!(m)
    buf = IOBuffer()
    if seed == ""
        seed = string(rand(alphabet))
    end
    write(buf, seed)
    c = wsample(alphabet, softmax(m.(map(c -> onehot(c, alphabet), collect(seed)))[end]))
    for i = 1:len
        write(buf, c)
        c = wsample(alphabet, softmax(m(onehot(c, alphabet))))
    end
    return String(take!(buf))
end

cd(@__DIR__)
m = train()


sample(m, alphabet, 1000) |> println



function getdata(args)
    # Download the data if not downloaded as 'input.txt'
    isfile("input.txt") ||
        download("https://cs.stanford.edu/people/karpathy/char-rnn/shakespeare_input.txt","input.txt")

    text = collect(String(read("input.txt")))
    
    # an array of all unique characters
    alphabet = [unique(text)..., '_']
    
    text = map(ch -> onehot(ch, alphabet), text)
    stop = onehot('_', alphabet)

    N = length(alphabet)
    
    # Partitioning the data as sequence of batches, which are then collected as array of batches
    Xs = collect(partition(batchseq(chunk(text, args.nbatch), stop), args.seqlen))
    Ys = collect(partition(batchseq(chunk(text[2:end], args.nbatch), stop), args.seqlen))

    return Xs, Ys, N, alphabet
end


seq = [rand(10) for i = 1:10]
m = Chain(LSTM(10, 15), Dense(15, 5))
m.(seq)