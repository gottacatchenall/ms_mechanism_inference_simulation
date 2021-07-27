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
    lakes = ["WEST LONG", "PAUL", "EAST LONG", "PETER"]
    justfish = CSV.read(joinpath(".", filename), DataFrame)

    # lakes with at least 10% occupancy across any species/year
    years = unique(justfish[!, :year4])
    tensor = zeros((length(species), length(lakes), length(years)))



    # not good code 
    for (li, lake) in enumerate(lakes)
        for (si, sp) in enumerate(species)
            for (yi, year) in enumerate(years)
                # lake 5 has no occupancy for any species so cut it out
                hereandnow = filter(
                        [:species, :year4, :lakename] => 
                        (s,y, l) -> s == sp && y == year && l == lake && li != 5, justfish
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
    data::Vector; 
    priorC = Beta(1,2),
    priorE = Beta(1,2),
    ρ = 0.1,
    chainsteps = 10000)

    if sum(data) < 1 
        return zeros(chainsteps), zeros(chainsteps)
    end

    postE = zeros(chainsteps)
    postC = zeros(chainsteps)
    i = 1
    while i < chainsteps 
        ehat = rand(priorE)
        chat = rand(priorC)
    #    @info "Proposed (E,C) = ($ehat, $chat)"
        sampledtraj = generate_trajectory(chat, ehat)
        statprime = summarystats(sampledtraj)


        stat = summarystats(data)
        sumstatdist = sqrt(sum((statprime .- stat).^2))
        if sumstatdist < ρ
            #      @info "\t Accepted"
            postE[i] = ehat
            postC[i] = chat
            i += 1
            i % 2500 == 0 && @info "chainstep: $i / $chainsteps"       
        end
    end
    return (postC, postE)
end


function abc(tensor; ρ = 0.1, chainsteps=10000)
    nspecies = size(tensor)[1]
    nlocations = size(tensor)[2]
    posteriorC = fill(zeros(chainsteps), nspecies,nlocations)
    posteriorE = fill(zeros(chainsteps), nspecies,nlocations)

    for l in 1:nlocations
        @info "lake $l of $nlocations" 
        for s in 1:nspecies
            traj = vec(tensor[s,l,:])
            postC, postE = sample(traj, ρ=ρ, chainsteps=chainsteps)
            
            posteriorC[s,l] = postC
            posteriorE[s,l] = postE
        end
    end
    return posteriorC, posteriorE
end


function forecast(previousstate, truenextstate, postC, postE; ntimesteps=1, nsamples = 10000)
    tp, tn, fn, fp = 0, 0, 0, 0 
    for s in 1:nsamples
        c = rand(postC)  #TODO FIX
        e = rand(postE)  # TODO FIX

        prediction = Bool(generate_trajectory(c,e, ntimesteps=2, init = previousstate)[2])
        truth = Bool(truenextstate)
        
        tp += truth & prediction
        tn += !truth & !prediction
        fp += !truth & prediction
        fn += truth & !prediction
     end

     # Diagnostic measures
    tpr = tp / (tp + fn) 
    fpr = fp / (fp + tn)
    tnr = tn / (tn + fp)
    fnr = fn / (fn + tp)

    ret = map(x -> !isnan(x) ? x : 0 , [tpr, tnr, fpr, fnr])
    return ret
end



training, test, species, lakes = getdata()


postC, postE = abc(training, ρ=0.1)


trainingyears = 5:19

meanTNR = []
meanTPR = []
meanFPR = []
meanFNR = []


for ty in trainingyears

    training, test, species, lakes = getdata(trainingyears=ty)
    totalTPR, totalTNR, totalFPR, totalFNR, repct = 0,0,0,0,0

    postC, postE = abc(training, ρ=0.1)


    for s in 1:length(species)
        for l in 1:length(lakes)
            tpr, tnr, fpr, fnr = forecast(training[s,l,end], test[s,l,begin], postC[s,l], postE[s,l])
            
            totalTPR += tpr
            totalTNR += tnr
            totalFPR += fpr
            totalFNR += fnr
            repct += 1
        end
    end

    push!(meanTNR, totalTNR/repct)
    push!(meanTPR, totalTPR/repct) 
    push!(meanFNR, totalFNR/repct) 
    push!(meanFPR, totalFPR/repct)
end


plot(trainingyears, meanTPR)
















"""

    Plotting posterior dist for each species/lake


"""
postplots  = []

for s in 1:length(species)
    for l in 1:length(lakes)
        push!(postplots, scatter(postC[s,l], postE[s,l], ma=0.03))
    end
end

plot(postplots...)



function plot_occupancy(tensor)
    nyr = size(tensor)[3]
    plots = []
    for s in 1:size(tensor)[1]
        for l in 1:size(tensor)[2]
            push!(plots, scatter(1:nyr, tensor[s,l,:], title="$s, $l"))
        end
    end
    plot(plots...)
end