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

    @info "Using the first $trainingyears years of the total $(length(years)) as training data"

    training = tensor[:,:,begin:trainingyears]
    test = tensor[:,:,trainingyears+1:end]

    return training, test, species, lakes
end

# 1) all species unique occupancy dynamics
function generate_trajectory(
    c,
    e; 
    nreps=1, 
    ntimesteps=100, 
    init = 1,
)
    trajectory = zeros(nreps, ntimesteps)
    trajectory[:, begin] .= init

    for r in 1:nreps
        for t in 2:ntimesteps
            oldstate = trajectory[r,t-1]
            if oldstate[r] == 1 && rand() < e
                trajectory[r,t] = 0
            elseif oldstate[r] == 0 && rand() < c
                trajectory[r,t] = 1
            else 
                trajectory[r,t] =  trajectory[r,t-1]
            end
        end
    end
    return trajectory
end


function summarystats(traj)
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

function sample(
    data::Matrix; 
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
        sampledtraj = generate_trajectory(chat, ehat)

        statprime = summarystats(sampledtraj)
        stat = summarystats(data)

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
function separatespeciesabc(data; ρ = [0.1 for i in 1:4])
    nspecies= size(data)[1]
    @assert nspecies == length(ρ)
    nlocations= size(data)[2]

    posteriorC = []
    posteriorE = []

    for s in 1:nspecies
        @info "Species $s of $nspecies" 
        postC, postE = sample(data[s, :,:], ρ=ρ[s])
        
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
        postC, postE = sample(data[:, l,:], ρ=ρ)
        
        push!(posteriorC, postC)
        push!(posteriorE, postE)
    end

    return posteriorC, posteriorE
end


function forecast(testdata, postC, postE; nsamples = 10000)

    nrep = size(testdata)[1]

    ntimesteps = size(testdata)[2]

    tp = 0
    tn = 0
    fn = 0
    fp = 0

    for s in 1:nsamples
        for r in 1:nrep
            c = rand(postC)
            e = rand(postE)
            test = Bool.(testdata[r,:])
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
    return (tpr, tnr, fpr, fnr)
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



separateLakeC,separateLakeE = separatelocationabc(training, ρ=0.1)
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


separateSpeciesC,separateSpeciesE = separatespeciesabc(training, ρ = [0.1, 0.05, 0.05, 0.05])
separateLakeC,separateLakeE = separatelocationabc(training, ρ=0.1)

forecast(test[1,:,:], separateSpeciesC[1],separateSpeciesE[1])
forecast(test[:,1,:], separateLakeC[1],separateLakeE[1])