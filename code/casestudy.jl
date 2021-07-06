using CSV, DataFrames
using Plots
using StatsBase
using StatsPlots
using Distributions
using ProgressMeter

const specieslist = ["LARGEMOUTHBASS", "SMALLMOUTHBASS", "YELLOWPERCH", "PUMPKINSEED"]

function read_data(; filename = "LTERwisconsinfish.csv")
    justfish = CSV.read(joinpath(".", filename), DataFrame)
    species = specieslist
    lakes = unique(justfish[!,:lakename])
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

    # split into test and training by defining a given number of training years

    return tensor
    
end


function plot_meanoccupancy(df)
    species = specieslist;
    lakes = unique(df[!,:lakename])
    years = unique(df[!, :year4])
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
end



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
                elseif oldstate[l] == 0 && rand() < c && sum(oldstate) > 0 
                    trajectory[s,l,t] = 1
                else 
                    trajectory[s,l,t] =  trajectory[s,l,t-1]
                end
            end
        end
    end
    return trajectory
end


# --------------------------------------------------------
# ABC rejection sampling fit to LARGEMOUTHBASS
#
# --------------------------------------------------------

function independentrejectionsample(
    data::Array; 
    priorC = Beta(1,2), 
    priorE = Beta(1,2),  
    ρ = 0.1, 
    chainsteps = 10000)

    postE = zeros(chainsteps)
    postC = zeros(chainsteps)
    i = 1
    while i < chainsteps 
        ehat = rand(priorE)
        chat = rand(priorC)

    #    @info "Proposed (E,C) = ($ehat, $chat)"

        sampledtraj = singlespeciesocc(chat, ehat)

        statprime = singlespeciessummarystats(sampledtraj)
        stat = singlespeciessummarystats(data)

        sumsatdist = sqrt(sum((statprime .- stat).^2))
    #    @info "Distance ($sumsatdist) from empircal (E,C)"


        if sumsatdist < ρ
    #      @info "\t Accepted"
            postE[i] = ehat
            postC[i] = chat
            i += 1
            i % 1000 == 0 && @info "chainstep: $i / $chainsteps"       
        end
    end
    return (postC, postE)
end

# rejection sampling ABC based on tolerance ρ
function independentabc(data; kw...)

    nspecies= size(data)[1]
    nlocations= size(data)[2]

    # do a chain for each species
    posteriorC = []
    posteriorE = []

    for s in 1:nspecies
        @info "Species $s of $nspecies" 
        postC, postE = independentrejectionsample(data[s, :,:]; kw...)
        
        push!(posteriorC, postC)
        push!(posteriorE, postE)
    end

    return posteriorC, posteriorE
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
    return [mnturnoverrate, globalmeanocc, globalvarocc]
end

c,e = independentabc(tensor, ρ = 0.15)
plots = []
for s in 1:4
    x,y =  c[s], e[s]
    plt  = scatter(x,y,size=(500,500),label="post", mc=:purple, ma=0.03,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1))
    title!(species[s])
    push!(plots, plt)
end
plot(plots...)

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
c,e = independentabc(pseudodata, ρ = 0.2)

plt  = scatter(size=(500,500),label="prior", mc=:purple, ma=0.03,  aspectratio=1, frame=:box, xlims=(0,1), ylims=(0,1))
scatter!(c[1,:],e[1,:], ma=0.01, mc=:dodgerblue, label="posterior")
scatter!([realc], [reale], ms=10, mc=:green)

savefig(plt, "singlespeciesfit.png")
# now generte predictions of future trajectories by taking 
# the most recent state as an initial condition and generate traj




# ---------------------------------------------------------------
#  
#   multispecies
#
# ---------------------------------------------------------------

# 2) cooccurence covar matrix blah 
function multispeciesocc(A, N; nspecies=4, nlocations=10, ntimesteps=100, kw...)
    trajectory = zeros(nspecies, nlocations, ntimesteps)
    trajectory[:, :, begin] = broadcast(x->rand() < 0.5, zeros(nspecies, nlocations)) 

    for t in 2:ntimesteps
    
        for l in 1:nlocations 
            for s in 1:nspecies
                # Pr(C_ik) for species i at location k = A_ss + sum_{s neq j} (A_sj)(O_jk)
                # Pr(E_ik) for species i at location k = N_ss + sum_{s neq j} (N_sj)(O_jk)
                c_sl = A[s,s]
                e_sl = N[s,s]
                for s2 in 1:nspecies
                    c_sl += A[s,s2]*trajectory[s2,l,t-1]
                    e_sl += N[s,s2]*trajectory[s2,l,t-1]
                end

                if trajectory[s,l,t-1] == 0 && rand() < c_sl
                    trajectory[s,l,t] = 1
                elseif trajectory[s,l,t-1] == 1 && rand() < e_sl
                    trajectory[s,l,t] = 0
                else
                    trajectory[s,l,t] = trajectory[s,l,t-1]
                end
            end
        end
    end
    return trajectory
end

# rejection sampling ABC based on tolerance ρ
function multispeciesabc(data; 
    ρ = 0.2,
    priorC = Beta(1,2), 
    priorE = Beta(1,2), 
    priorLambda = Exponential(0.03), 
    priorGamma = Exponential(0.01), chainsteps = 5000, kw...)

    postC = zeros(chainsteps);
    postE = zeros(chainsteps);
    postLambda = zeros(chainsteps);
    postGamma = zeros(chainsteps);
    

    numspecies = size(data)[1]

    i = 1
    while i < chainsteps 
        ehat = rand(priorE)
        chat = rand(priorC)
        lambdahat = rand(priorLambda)
        gammahat = rand(priorGamma)

        A, N = zeros(numspecies,numspecies), zeros(numspecies, numspecies)

        for i in 1:numspecies, j in 1:numspecies
            if i == j 
                A[i,j] = rand(priorC)
                N[i,j] = rand(priorE)
            else
                A[i,j] = rand(priorLambda)
                N[i,j] = rand(priorGamma)
            end
        end


        sampledtraj = multispeciesocc(A, N; kw...)

        statprime = multispeciessummarystats(sampledtraj)
        stat = multispeciessummarystats(data)

        sumsatdist = sqrt(sum((statprime .- stat).^2))
       # @info "Distance ($sumsatdist) from empircal (E,C)"


        if sumsatdist < ρ
         # @info "\t Accepted"
            postE[i] = ehat
            postC[i] = chat
            postGamma[i] = gammahat
            postLambda[i] = lambdahat
            i += 1
            i % 1000 == 0 && @info "chainstep: $i / $chainsteps"       
        end
    end
    return postC, postE, postLambda, postGamma
end

function multispeciessummarystats(traj)
    # synchrony of mean occuapcny 
    nspecies = size(traj)[1]
    nlocations = size(traj)[2]
    
    mnturnoverrate,globalmeanocc, globalvarocc = singlespeciessummarystats(traj)

    mnocc = [[mean(tensor[s,:,i]) for i in 1:length(years)] for s in 1:nspecies]

    sumcrosscov = 0 
    counter = 0

    for l in 1:nlocations
        for s1 in 1:nspecies, s2 in 1:nspecies
            if (s1 != s2)
                cc = crosscov(mnocc[s1], mnocc[s2], [0])
                sumcrosscov += cc[1]
                counter += 1
            end
        end
    end

    mnsynchrony = sumcrosscov/counter
    return [mnturnoverrate,globalmeanocc, globalvarocc, mnsynchrony]
end


priorC = Beta(1,2) 
priorE = Beta(1,2)
priorLambda = Exponential(0.03)
priorGamma = Exponential(0.01)

postC, postE, postLambda, postGamma = multispeciesabc(tensor, ρ=0.1, priorC=priorC, priorE=priorE, priorGamma=priorGamma, priorLambda=priorLambda)


scatter(
    postC, postE,
    size=(500,500),
    mc=:dodgerblue, 
    ma=0.4,  
    aspectratio=1, 
    frame=:box, 
    xlims=(0,1), 
    ylims=(0,1))
scatter!(rand(priorC, 1000), rand(priorE, 1000), mc=:orange, ma=0.1)

scatter(
size=(500,500),
mc=:dodgerblue, 
aspectratio=1, 
frame=:box)
scatter!(rand(priorLambda, 1000), rand(priorGamma, 1000), mc=:orange, ma=0.04)
scatter!(postLambda, postGamma, ma=0.04, mc=:dodgerblue)

histogram(postC)