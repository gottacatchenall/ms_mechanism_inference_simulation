using EcologicalNetworks: degree_in_var
using EcologicalNetworks
using Flux
using Plots
using StatsBase: mean, var, sample
using ProgressMeter
include("01_get_test_training_splits.jl")
# generate model given params

function get_features_and_labels(net)
    # for every interaction, train the thing 
    summstats = summarystats(net)
    nf = length(summstats) + 2
    S = richness(net)
    features = zeros(Float64, nf, S^2)
    labels = zeros(Bool, S^2)
    trophicdict = trophic_level(net)
    cursor = 1

    for i in 1:S, j in 1:S
        trophic_i = trophicdict["s$i"]
        trophic_j = trophicdict["s$j"]

        features[:, cursor] = [summstats..., trophic_i, trophic_j]
        if (net[i,j])
            labels[cursor] =  true
        end
        cursor += 1
    end
    return features, labels
end


function get_featlab_for_whole_set(set)
    feat, lab = [], []
    for net in set
        f, l = get_features_and_labels(net)
        push!(feat, f)
        push!(lab, l)
    end
    return feat, lab
end

function learn!(net, loss, ps, opt; nf=4)
    data_batch = get_features_and_labels(net)
    Flux.train!(loss, ps, [data_batch], opt)
end

function trainmodel(model, trainingset, testset; nrounds = 500, generatorsize = 30, batchsize=32)
    Flux.reset!(model)

    loss(x, y) = Flux.mse(model(x), y)
    ps = Flux.params(m)
    opt = ADAM() 

    mat_at = 50
    epc = mat_at:mat_at:nrounds
    epc = vcat(1, epc...)

    trainlossvalue = zeros(length(epc))
    testlossvalue = zeros(length(epc))
    epccursor= 1
    @showprogress for r in 1:nrounds

        tr = sample(trainingset, batchsize; replace=false)

        for A in tr
            empirical_connectance = connectance(A)
            candidate = nichemodel(generatorsize, empirical_connectance)
            learn!(candidate, loss, ps, opt)
        end 

        if r in epc
            tes = sample(testset, batchsize; replace=false)

            trainfeat, trainlab = get_featlab_for_whole_set(tr)
            testfeat, testlab = get_featlab_for_whole_set(tes)

            trainlossvalue[epccursor] = mean(loss.(trainfeat, trainlab))
            testlossvalue[epccursor] = mean(loss.(testfeat, testlab))
            epccursor += 1
        end
    end

    return epc, trainlossvalue, testlossvalue
end


#=
training, test = get_data()
filter!(x-> richness(x) < 75, training)
filter!(x-> richness(x) > 10, training)


function summarystats(net)
    Kin = values(EcologicalNetworks.degree_in(net))
    troph = values(trophic_level(net))

    c = connectance(net)
    meantrophic = mean(troph)
    vartrophic = var(troph)
    Kin_bar = mean(Kin)
    Kin_var = var(Kin)
    return [c, Kin_bar, Kin_var, meantrophic, vartrophic]
end

summarystatdims = 5
nf = summarystatdims + 2

m = Chain(
    Dense(nf, 2nf, Flux.relu),
    Dense(2nf, 1, σ)
)

epc, trainloss, testloss = trainmodel(m, training, test, nrounds=500)


plot(epc, trainloss; lab="Training", dpi=600, frame=:box, size=(400, 400))
plot!(epc, testloss; lab="Testing")
xaxis!("Epoch")
yaxis!("Loss (MSE)")

savefig("attemptedloss_deepermodel.png")
=#

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


    