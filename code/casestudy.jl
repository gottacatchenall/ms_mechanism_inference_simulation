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
function singlespeciesocc(c,e; nspecies=1, nlocations=10, ntimesteps=100)
    trajectory = zeros(nspecies, nlocations, ntimesteps)
    trajectory[:, :, begin] = broadcast(x->rand() < 0.5, zeros(nspecies, nlocations)) 

    for s in 1:nspecies
        for t in 2:ntimesteps
            oldstate = trajectory[s,:,t-1]
            for l in 1:nlocations
                if oldstate[l] == 1 && rand() < e
                    trajectory[s,l,t] = 0
                elseif oldstate[l] == 0 && rand() < c
                    trajectory[s,l,t] = 1
                else 
                    trajectory[s,l,t] =  trajectory[s,l,t-1]
                end
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
function independentabc(data; priorC = Beta(1,2), priorE = Beta(1,2), ρ = 0.1, chainsteps = 10000)

    nspecies= size(data)[1]
    nlocations= size(data)[2]


    postE = zeros(nspecies, chainsteps)
    postC = zeros(nspecies, chainsteps)

    # do a chain for each species
    for s in 1:nspecies
        @info "Species $s of $nspecies" 
        i = 1
        while i < chainsteps 
            ehat = rand(priorE)
            chat = rand(priorC)

        #    @info "Proposed (E,C) = ($ehat, $chat)"

            sampledtraj = singlespeciesocc(chat, ehat)

            statprime = singlespeciessummarystats(sampledtraj)
            stat = singlespeciessummarystats(data[s,:,:])

            sumsatdist = sqrt(sum((statprime .- stat).^2))
        #    @info "Distance ($sumsatdist) from empircal (E,C)"


            if sumsatdist < ρ
          #      @info "\t Accepted"
                postE[s,i] = ehat
                postC[s,i] = chat
                i += 1
                i % 1000 == 0 && @info "chainstep: $i / $chainsteps"       
            end
        end
    end

    return postC, postE
end


function singlespeciessummarystats(traj)
    nspecies = size(traj)[1]
    nlocations = size(traj)[2]
    globalmeanocc = mean(traj)
    globalvarocc = std(traj)

    ct = 0 
    tos = 0 
    for s in 1:nspecies
        for l in 1:nlocations
            turnoverrate = (Vector{Int32}(traj[s,l,1:(end-1)] .!= traj[s,l,2:end]))
            tos += mean(turnoverrate)
            ct += 1
        end
    end

    mnturnoverrate = !isnan(tos/ct) ? (tos/ct) :  0
    return [mnturnoverrate,globalmeanocc, globalvarocc]
end

# time series for Large Mouthbass across locations 
LMB = tensor[1,:,:]

priorC = Beta(1,2)
priorE = Beta(1,2)

"""
c,e = independentabc(tensor, ρ = 0.9, priorC=priorC, priorE=priorE)
histogram(c[1,:], label="post", color=:red, alpha=0.3)
histogram!(rand(priorC, 1000), label="prior", color=:dodgerblue, alpha=0.3)

histogram(e[1,:], label="post", color=:red, alpha=0.3)
histogram!(rand(priorE, 1000), label="prior", color=:dodgerblue, alpha=0.3)
"""

## compare to known data
realc, reale = 0.3, 0.1
pseudodata = singlespeciesocc(realc, reale)
c,e = independentabc(pseudodata, ρ = 0.2, priorC=priorC, priorE=priorE)

plt  = scatter(rand(priorC, 10000), rand(priorE, 10000), size=(500,500),label="prior", mc=:purple, ma=0.03,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1))
scatter!(c[1,:],e[1,:], ma=0.05, mc=:dodgerblue, label="posterior")
scatter!([realc], [reale], ms=10, mc=:green)

savefig(plt, "singlespeciesfit.png")

