using EcologicalNetworks
using Flux
using Plots
using StatsBase: mean, var, sample
using ProgressMeter
using JSON
include("02_generative_models.jl")


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



training, test = get_data()
filter!(x-> richness(x) < 75, training)
filter!(x-> richness(x) > 10, training)

summarystatdims = 5
nf = summarystatdims + 2

m = Chain(
    Dense(nf, 3, relu),
    Dropout(0.6),
    Dense(3, 1, σ)
)

epc, trainloss, testloss = trainmodel(m, training, test, nrounds=5000)


# We get the predictions and observations for the testing dataset

testfeat, testlabs = get_featlab_for_whole_set(test)



predvec = m.(testfeat)
obsvec = vec(testlabs)


predictions = []
obs = []

for i in 1:length(obsvec)
    push!(predictions, predvec[i]...)
    push!(obs, obsvec[i]...)
end


# And we pick thresholds in the [0,1] range
thresholds = range(0.0, 1.0; length=500)

# All this is going to be the components of the adjacency matrix at a given threshold
tp = zeros(Float64, length(thresholds))
fp = zeros(Float64, length(thresholds))
tn = zeros(Float64, length(thresholds))
fn = zeros(Float64, length(thresholds))

# Main loop to get the four components
for (i, thr) in enumerate(thresholds)
    pred = vec(predictions .>= thr)
    tp[i] = sum(pred .& obs)
    tn[i] = sum(.!(pred) .& (.!obs))
    fp[i] = sum(pred .& (.!obs))
    fn[i] = sum(.!(pred) .& obs)
end



# Total number of cases
n = tp .+ fp .+ tn .+ fn

# Diagnostic measures
tpr = tp ./ (tp .+ fn)
fpr = fp ./ (fp .+ tn)
tnr = tn ./ (tn .+ fp)
fnr = fn ./ (fn .+ tp)
acc = (tp .+ tn) ./ (n)
racc = ((tn .+ fp) .* (tn .+ fn) .+ (fn .+ tp) .* (fp .+ tp)) ./ (n .* n)
bacc = ((tp ./ (tp .+ fn)) .+ (tn ./ (fp .+ tn))) ./ 2.0
J = (tp ./ (tp .+ fn)) + (tn ./ (tn .+ fp)) .- 1.0
κ = (acc .- racc) ./ (1.0 .- racc)
threat = tp ./ (tp .+ fn .+ fp)
fomrate = fn ./ (fn .+ tn)
fdirate = fp ./ (fp .+ tp)
ppv = tp ./ (tp .+ fp)
npv = tn ./ (tn .+ fn)

# This bit is here to get the AUC
dx = [reverse(fpr)[i] - reverse(fpr)[i - 1] for i in 2:length(fpr)]
dy = [reverse(tpr)[i] + reverse(tpr)[i - 1] for i in 2:length(tpr)]
AUC = sum(dx .* (dy ./ 2.0))

# Final thresholding results - we pick the value maximizing Youden's J
thr_index = last(findmax(J))
thr_final = thresholds[thr_index]

# Save the validation measures to a plot
validation = Dict{String,Float64}()
validation["ROC-AUC"] = AUC
validation["Threat score"] = threat[thr_index]
validation["Youden's J"] = J[thr_index]
validation["True Positive Rate"] = tpr[thr_index]
validation["True Negative Rate"] = tnr[thr_index]
validation["False Positive Rate"] = fpr[thr_index]
validation["False Negative Rate"] = fnr[thr_index]
validation["Kappa"] = κ[thr_index]
validation["Accuracy"] = acc[thr_index]
validation["Accuracy (random)"] = racc[thr_index]
validation["Accuracy (balanced)"] = bacc[thr_index]
validation["False Discovery Rate"] = fdirate[thr_index]
validation["False Omission Rate"] = fomrate[thr_index]
validation["Positive Predictive Value"] = ppv[thr_index]
validation["Negative Predictive Value"] = npv[thr_index]

open("validation.json", "w") do f
    JSON.print(f, validation, 4)
end


plot(fpr, tpr; aspectratio=1, frame=:box, lab="", dpi=600, size=(400, 400))
scatter!([fpr[thr_index]], [tpr[thr_index]]; lab="", c=:black)
plot!([0, 1], [0, 1]; c=:grey, ls=:dash, lab="")
xaxis!("False positive rate", (0, 1))
yaxis!("True positive rate", (0, 1))

# We also save this one to a file
savefig("roc-auc.png")

# Precision-Recall plot
plot(tpr, ppv; aspectratio=1, frame=:box, lab="", dpi=600, size=(400, 400))
scatter!([tpr[thr_index]], [ppv[thr_index]]; lab="", c=:black)
plot!([0, 1], [1, 0]; c=:grey, ls=:dash, lab="")
xaxis!("True positive rate", (0, 1))
yaxis!("Positive predictive value", (0, 1))

# We also save this one to a file
savefig("precision-recall.png")