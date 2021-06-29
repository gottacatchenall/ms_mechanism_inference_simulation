using CSV, DataFrames
using Plots
using StatsBase
using Distributions

justfish = CSV.read(joinpath("code", "LTERwisconsinfish.csv"), DataFrame)


years = unique(justfish[!, :year4])
species = ["LARGEMOUTHBASS", "SMALLMOUTHBASS", "YELLOWPERCH", "PUMPKINSEED", "MUDMINNOW"]
lakes = unique(justfish[!,:lakename])

tensor = zeros((length(species), length(lakes), length(years)))

# not good code 
for (li, lake) in enumerate(lakes)
    for (si, sp) in enumerate(species)
        for (yi, year) in enumerate(years)
            hereandnow = filter([:species, :year4, :lakename] => (s,y, l) -> s == sp && y == year && l == lake, justfish)
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

LMB = tensor[1,:,:]

priorE = Beta(1,2)
priorC = Beta(1,2)


chainsteps = 100000

postE = zeros(chainsteps)
postC = zeros(chainsteps)

step = 1
ρ = 0.1
while step < chainsteps
    # draw candidate params 
    ehat = rand(priorE)
    chat = rand(priorC)

    sampledtraj = singlespeciesocc(chat, ehat)

    sumsatdist = summarystats(sampledtraj, LMB)
    
    if sumsatdist < ρ
        postE[step] = ehat
        postC[step] = chat
        step += 1
    end
end

function summarystats(simtrajectory, empiricaltrajectory)
    # meanocc
    # varocc
    # 
    


end