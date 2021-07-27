import Flux
using Flux: RNN, Chain, Dense, ADAM, params, σ, onehot

function loss(x, y)
  sum((Flux.stack(m.(x),1) .- y) .^ 2)
end

function getfeatures(tensor) 
  nspecies = size(tensor)[1]
  nlocations = size(tensor)[2]

  featuredims = size(tensor)[3] + 1

  features, labels = [], zeros(1, nspecies*nlocations)

  cursor = 1
  for s in 1:nspecies
      for l in 1:nlocations
          thisfeaturesvec = vec([s,l, tensor[s,l,1:end-1]...])
          thislabel = tensor[s,l,end]

          push!(features, thisfeaturesvec)
          labels[cursor] = thislabel
          cursor += 1
      end
  end

  return features, labels
end 


training, test, sp, lakes = getdata()

featureDims = 10
numFeatures = 30

seq_1 = [onehot(1, rand(Bool, featureDims)) for i = 1:numFeatures]
seq_2 = [onehot(1, rand(Bool, featureDims)) for i = 1:numFeatures]

seq_1 = [Float32.(training[1,s,:]) for s = 1:4, l = 1:4]
seq_2 = [Float32.(training[2,s,:]) for s = 1:4, l = 1:4]


y1 = [Float32.(test[1,s, begin]) for s = 1:4]
y2 = [Float32.(test[2,s, begin]) for s = 1:4]

X = [seq_1, seq_2]
Y = [y1, y2]
data = zip(X,Y)

m = Chain(RNN(length(seq_1[1]), 5), Dense(5, 1, σ), x -> reshape(x, :))


Flux.reset!(m)

ps = params(m)
opt= ADAM(1e-3)
Flux.train!(loss, ps, data, opt)


seq_2
m.(seq_2) 
y2