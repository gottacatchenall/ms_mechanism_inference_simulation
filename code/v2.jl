using CSV: size
using CSV, DataFrames
using Plots
using StatsBase
using StatsPlots
using Distributions
using ProgressMeter

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

# 1) all species unique occupancy dynamics
function generate_trajectory(
    c,
    e; 
    ntimesteps=100, 
    init = 1,
)
    trajectory = zeros(ntimesteps)
    trajectory[begin] = init

        for t in 2:ntimesteps
            oldstate = trajectory[t-1]
            if oldstate == 1 && rand() < e
                trajectory[t] = 0
            elseif oldstate == 0 && rand() < c
                trajectory[t] = 1
            else 
                trajectory[t] =  trajectory[t-1]
            end
        end
    return trajectory
end


function summarystats(traj)
    globalmeanocc = mean(traj)
    globalvarocc = std(traj)
    turnoverrate = mean(Vector{Int32}(traj[1:(end-1)] .!= traj[2:end]))

    return [turnoverrate, globalmeanocc, globalvarocc]
end

function sample(
    data::Matrix; 
    priorC = Beta(1,2),
    priorE = Beta(1,2),
    ρ = 0.1,
    chainsteps = 10000)

    nreps = size(data)[1]

    postE = zeros(chainsteps)
    postC = zeros(chainsteps)
    i = 1
    while i < chainsteps 
        ehat = rand(priorE)
        chat = rand(priorC)
    #    @info "Proposed (E,C) = ($ehat, $chat)"
        sampledtraj = generate_trajectory(chat, ehat)


        
        statprime = summarystats(sampledtraj)
   
        meandist = 0
        for r in 1:nreps
            stat = summarystats(vec(data[r,:]))
            sumsatdist = sqrt(sum((statprime .- stat).^2))
            meandist += sumsatdist
        end 
        meandist = meandist/nreps

        if meandist < ρ
            #      @info "\t Accepted"
            postE[i] = ehat
            postC[i] = chat
            i += 1
            i % 2500 == 0 && @info "chainstep: $i / $chainsteps"       
        end
    end
    return (postC, postE)
end

# rejection sampling ABC based on tolerance ρ
function abc(data::Matrix; ρ = 0.1)
    nreps = size(data)[1]

    posteriorC = []
    posteriorE = []

    for r in 1:nreps
        @info "replicate $r of $nreps" 
            thisrep = Matrix(data[r,:])
            postC, postE = sample(thisrep, ρ=ρ)

        push!(posteriorC, postC)
        push!(posteriorE, postE)
    end

    return posteriorC, posteriorE
end


function separatelocationabc(data; ρ = 0.1)
    nlocations= size(data)[2]

    posteriorC = []
    posteriorE = []

    for l in 1:nlocations
        @info "lake $l of $nlocations" 
        thislakeovertime = Matrix(data[:,l,:])
        postC, postE = sample(thislakeovertime, ρ=ρ)
        
        push!(posteriorC, postC)
        push!(posteriorE, postE)
        
    end

    return posteriorC, posteriorE
end


function forecast(testdata, postC, postE; ntimesteps=1, nsamples = 10000)

    nrep = size(testdata)[1]


    tp = 0
    tn = 0
    fn = 0
    fp = 0

    for s in 1:nsamples
        for r in 1:nrep
            c = rand(postC)
            e = rand(postE)
            test = Bool.(testdata[r,begin:begin+ntimesteps-1])
            sampled = Bool.(generate_trajectory(c,e, ntimesteps=ntimesteps, init = test[1])[1,:])
            

            tp += sum(sampled .& test)
            tn += sum(.!(sampled) .& (.!test))
            fp += sum(sampled .& (.!test))
            fn += sum(.!(sampled) .& test)
        end
     end

    n = tp .+ fp .+ tn .+ fn

     # Diagnostic measures
    tpr = tp ./ (tp .+ fn) 
    fpr = fp ./ (fp .+ tn)
    tnr = tn ./ (tn .+ fp)
    fnr = fn ./ (fn .+ tp)

    ret = map(x -> !isnan(x) ? x : 0 , [tpr, tnr, fpr, fnr])


    return ret
end


training, test, species, lakes = getdata()

separateSpeciesC,separateSpeciesE = separatespeciesabc(training, ρ = [0.1, 0.05, 0.05, 0.05])

plots = []
push!(plots, scatter(rand(Beta(1,2), 5000), rand(Beta(1,2), 5000), title="Prior", ma=0.01, mc=:red, aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1), label="prior"))
for s in 1:4
    x,y =  c[s], e[s]
    postplt = scatter(x,y,size=(500,500),label="post", mc=:purple, ma=0.005,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1))
    title!(postplt, species[s])
    xlabel!("C")
    ylabel!("E")
    push!(plots, postplt)
end
plot(plots..., size=(900,900))



separateLakeC,separateLakeE = separatelocationabc(training, ρ=[0.05, 0.05, 0.05 ,0.05, 0.1, 0.05,0.05,0.05,0.05,0.1] )
plots = []
push!(plots, scatter(rand(Beta(1,2), 5000), rand(Beta(1,2), 5000), title="Prior", ma=0.01, mc=:red, aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1), label="prior"))
for l in 1:10
    x,y =  c[l], e[l]
    postplt = scatter(x,y,size=(500,500),label="post", mc=:purple, ma=0.005,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1))
    xlabel!("C")
    ylabel!("E")
    title!(postplt, lakes[l])
    push!(plots, postplt)
end
plot(plots..., size=(900,900))

savefig("separatelakes.png")

# ----------------------------------------------


training, test, species, lakes = getdata(trainingyears = 15)



## ----------------------------- the coool shit 

# number of trainining years on X axis
# TPR / TNR / FPR / FNR on Y axis
# mean across rep
# two panels: lake and species 

speciesFNR = zeros(length(species),20)
speciesFPR = zeros(length(species),20)
speciesTPR = zeros(length(species),20)
speciesTNR = zeros(length(species),20)

lakesFNR = zeros(length(lakes), 20)
lakesFPR = zeros(length(lakes), 20)
lakesTPR = zeros(length(lakes), 20)
lakesTNR = zeros(length(lakes), 20)

 

lakesFNR[1,:]

meanFNRspecies = [mean(speciesFNR[:, t]) for t in 1:20]
meanFPRspecies = [mean(speciesFPR[:, t]) for t in 1:20]
meanTNRspecies = [mean(speciesTNR[:, t]) for t in 1:20]
meanTPRspecies = [mean(speciesTPR[:, t]) for t in 1:20]

meanFNRlakes= [mean(lakesFNR[:, t]) for t in 1:20]
meanFPRlakes = [mean(lakesFPR[:, t]) for t in 1:20]
meanTNRlakes = [mean(lakesTNR[:, t]) for t in 1:20]
meanTPRlakes = [mean(lakesTPR[:, t]) for t in 1:20]


speciesplots = []
for s in 1:4
    plt = plot(title=species[s])
    scatter!(plt, trainyears, speciesTPR[s, :], label="TPR")
    scatter!(plt, trainyears, speciesTNR[s, :], ms=3, label="TNR",ylims=(0,1))
    scatter!(plt, trainyears, speciesFNR[s, :], label="FNR")
    scatter!(plt, trainyears, speciesFPR[s, :], label="FPR")

    push!(speciesplots, plt)
end
plot(speciesplots...)


tprPlot = plot(title="true positive rate", size=(900,900), legend=:none)
for s in 1:4
    scatter!(tprPlot, trainyears, speciesTPR[s, :], label="$(species[s])")
end
tprPlot

tnrPlot = plot(title="true negative rate",size=(900,900), legend=:none)
for s in 1:4
    scatter!(tnrPlot, trainyears, speciesTNR[s, :], label="$(species[s])")
end


fprPlot = plot(title="false positive rate",size=(900,900), legend=:none)
for s in 1:4
    scatter!(fprPlot, trainyears, speciesFPR[s, :], label="$(species[s])")
end

fnrPlot = plot(title="false negative rate", size=(900,900), legend=:none)
for s in 1:4
    scatter!(fnrPlot, trainyears, speciesFNR[s, :], label="$(species[s])")
end


plot(tprPlot, tnrPlot, fprPlot, fnrPlot, layout=(2,2), lp=:outside)








## compare to known data
realc, reale = 0.3, 0.1
nt = 40
ns = 3
pseudodata = zeros(ns,nt)
for i in 1:ns
    pseudodata[i, :] = generate_trajectory(realc, reale, ntimesteps=nt, init=1)
end
c,e = separatespeciesabc(pseudodata, ρ = 0.7)

plots = []
push!(plots, scatter(rand(Beta(1,2), 5000), rand(Beta(1,2), 5000), title="Prior", ma=0.03, mc=:red, aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1), label="prior"))
push!(plots, scatter(size=(500,500),label="prior", mc=:purple, ma=0.03,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1)))
scatter!(c[1,:],e[1,:], ma=0.01, mc=:dodgerblue, label="posterior")
scatter!([realc], [reale], label="true parameters", ms=10, mc=:green)
plot(plots..., size=(800,800))
