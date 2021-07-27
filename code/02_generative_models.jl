using EcologicalNetworks
using Flux
using StatsBase: mean, var
using ProgressMeter
include("01_get_test_training_splits.jl")
# generate model given params

function generate(A) 
    return nichemodel(UnipartiteNetwork(Bool.(A)))
end 

function summarystats(net)
    ent = entropy(net)
    meantrophic = mean(values(trophic_level(net)))
    # vartrophic = var(values(trophic_level(net)))
    return [ent, meantrophic]
end

function get_features_and_labels(adjmatrix)
    # for every interaction, train the thing 

    features = zeros(Float64, nf, S^2)
    labels = zeros(Bool, S^2)

    cursor = 1
    for i in 1:S, j in 1:S
        trophic_i = trophicdict["s$i"]
        trophic_j = trophicdict["s$j"]
        features[:, cursor] = [summstats..., trophic_i, trophic_j]
        labels[cursor] =  Bool(net[i,j])
    end
    return features, labels
end

function learn!(model, net, loss, ps, opt; nf=4)
    data_batch = get_features_and_labels(net)
    Flux.train!(loss, ps, [data_batch], opt)
    
end

function trainmodel(model, trainingset; nrounds = 500, ρ=0.5)
    Flux.reset!(model)

    loss(x, y) = Flux.mse(model(x), y)
    ps = Flux.params(m)
    opt = ADAM() 


    trainlossvalue = zeros(nrounds)
    testlossvalue = zeros(nrounds)
    @showprogress for r in 1:nrounds
        for A in trainingset
            candidate = generate(A)
            learn!(model, candidate, loss, ps, opt)
        end

        if i in epc
            trainlossvalue[i] = loss(...)
            testlossvalue[i] = loss(data_test...)
        end
    end
end


training, test = get_data()
filter!(x-> size(x)[1] < 100, training)
filter!(x-> size(x)[1] > 8, training)


summarystatdims = 2
nf = summarystatdims + 2
m = Chain(
    Dense(nf, 1,  σ),
    Dense(1, 1, σ),
)

trainmodel(m, training, nrounds=2)


# old rejection samp code
        #    accepted = false
        #    tryct = 0
        #    while !accepted 
        #        candidate = generate(A)
        #        realfeatures, simfeatures = summarystats(UnipartiteNetwork(Bool.(A))), summarystats(candidate)
        #        dist = sqrt(sum((realfeatures .- simfeatures).^2))
        #        if (dist < ρ)
        #            accepted = true
        #            learn!(model, candidate)
        #        end
        #        tryct += 1
        #    end 
        #    @info "accept rate: $(1.0/tryct)"