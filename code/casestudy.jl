using CSV, DataFrames
using Plots
using StatsBase
using StatsPlots
using Distributions
using ProgressMeter

justfish = CSV.read(joinpath(".", "LTERwisconsinfish.csv"), DataFrame)


years = unique(justfish[!, :year4])
species = ["LARGEMOUTHBASS", "SMALLMOUTHBASS", "YELLOWPERCH", "PUMPKINSEED", "MUDMINNOW"]
lakes = unique(justfish[!,:lakename])

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

# plot mean occ by species 
plotsvec = []
for s in 1:length(species)
    plt = plot(legend=:none, frame=:box, title="$(species[s])")

    mns = [mean(tensor[s,:,i]) for i in 1:length(years)]

    df = sort(DataFrame(years=years,mns=mns), [:years])
    scatter!(plt, df.years,df.mns, ma=0.5)

    plot!(plt, df.years,df.mns, lc=:dodgerblue)
    push!(plotsvec, plt)
end
plot(plotsvec...,)




# now lets set up two generative models:


# 1) all species unique occupancy dynamics
function singlespeciesocc(c,e; nlocations=10, ntimesteps=100)
    trajectory = zeros(nlocations, ntimesteps)
    trajectory[:, begin] = broadcast(x->rand() < 0.5, zeros(nlocations)) 

    for t in 2:ntimesteps
        oldstate = trajectory[:,t-1]
        for l in 1:nlocations
            if oldstate[l] == 1 && rand() < e
                trajectory[l,t] = 0
            elseif oldstate[l] == 0 && rand() < c
                trajectory[l,t] = 1
            else 
                trajectory[l,t] =  trajectory[l,t-1]
            end
        end
    end
    return trajectory
end


# 2) cooccurence covar matrix blah 


# --------------------------------------------------------
# ABC rejection sampling fit to LARGEMOUTHBASS
#
# --------------------------------------------------------



# rejection sampling ABC based on tolerance ρ
function independentabc(data; priorC = Beta(1,2), priorE = Beta(1,2), ρ = 0.1, nspecies=5, nlocations=10, chainsteps = 10000)

    postE = zeros(nspecies, chainsteps)
    postC = zeros(nspecies, chainsteps)

    # do a chain for each species
    for s in 1:nspecies
        @info "Species $s of $nspecies" 
        i = 1
        while i < chainsteps 
            i % 100 == 0 && @info "chainstep: $i / $chainsteps"       
            ehat = rand(priorE)
            chat = rand(priorC)

            sampledtraj = singlespeciesocc(chat, ehat)

            statprime = summarystats(sampledtraj)
            stat = summarystats(data)

            sumsatdist = sqrt(sum((statprime .+ stat).^2))
            if sumsatdist < ρ
                postE[s,i] = ehat
                postC[s,i] = chat
                i += 1
            end
        end
    end

    return postC, postE
end

function summarystats(traj)
    globalmeanocc = mean(traj)
    globalvarocc = std(traj)
    return [globalmeanocc, globalvarocc]
end

# time series for Large Mouthbass across locations 
LMB = tensor[1,:,:]

priorC = Beta(1,2)
priorE = Beta(1,2)

c,e = independentabc(LMB, ρ = 0.8, priorC=priorC, priorE=priorE, nspecies=1)




histogram(c[1,:], label="post", color=:red, alpha=0.3)
histogram!(rand(priorC, 1000), label="prior", color=:dodgerblue, alpha=0.3)

histogram(e[1,:], label="post", color=:red, alpha=0.3)
histogram!(rand(priorE, 1000), label="prior", color=:dodgerblue, alpha=0.3)
