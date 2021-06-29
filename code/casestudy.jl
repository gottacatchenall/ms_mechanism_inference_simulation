using CSV, DataFrames
using Plots

justfish = CSV.read("/home/michael/data/LTERwisconsinfish.csv", DataFrame)


years = unique(justfish[!, :year4])
species = unique(justfish[!, :species])
lakes = unique(justfish[!,:lakename])

tensor = zeros((length(species), length(lakes), length(years)))

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


plotsvec = []
for l in 1:length(lakes)
    plt = plot(legend=:none, frame=:box)
    for s in 1:length(species)
        scatter!(plt, tensor[s,l,:], ma=0.3)
    end
    push!(plotsvec, plt)
end

plot(plotsvec...,)


# now lets set up two models:
# 1) all species unique occupancy dynamics
# 2) cooccurence matrix blah 

singlespeciesocc(c,e; ntimesteps) = 