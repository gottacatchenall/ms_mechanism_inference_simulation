using DataFrames, CSV
using Random: shuffle!
using EcologicalNetworks

function read_edgelist(filepath)
    df = CSV.read(filepath, DataFrame)

    sz = max(max(df.i...), max(df.j...))
    A = zeros(sz,sz)

    
    for r in 1:nrow(df)
        i = df[r, :i]
        j = df[r, :j]
        A[i,j] = 1
    end
    return UnipartiteNetwork(Bool.(A))
end


function get_data(;dir="assets", trainingprop=0.8)
    filenames = filter(x->endswith(x, ".csv"), readdir(dir))

    trainingsize = Int32(floor(trainingprop*length(filenames)))

    shuffle!(filenames)
    
    trainingfiles = filenames[1:trainingsize];
    testfiles = filenames[trainingsize+1:end];
    
    training = []
    test = []

    for f in trainingfiles
        push!(training, read_edgelist(joinpath(dir, f)))
    end

    for f in testfiles
        push!(test, read_edgelist(joinpath(dir, f)))
    end

    return training, test
end

training, test = get_data()
