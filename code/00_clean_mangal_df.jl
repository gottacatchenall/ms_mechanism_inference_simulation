using DataFrames, CSV
using SparseArrays
using EcologicalNetworks

foodwebs = CSV.read("./assets/foodwebs.csv", DataFrame)

thewebz = network.(foodwebs.id)

for w in thewebz
    thismat = convert(UnipartiteNetwork,w)
    pathname = joinpath("./assets/$(w.name).csv") 
    Is,Js,trash = findnz(thismat.edges)
    CSV.write(pathname,  DataFrame([Is, Js], [:i,:j]))
end



