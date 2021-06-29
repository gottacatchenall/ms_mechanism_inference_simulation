---
bibliography: [references.bib]
---


# Introduction

Earth's ecosystems are immensely variable---they are the emergent result of
biological processes that exist across spatial, temporal, and organizational
scales  [@Levin1992ProPat]. These processes enable, influence and compound on
one another, resulting in the immense diversity of functions and forms of life
on Earth. There has been a longstanding debate if there is any _generality_, or
better _universality_, to these processes [@Lawton1999]. Answering this
question itself proves difficult---how can we determine if there is some set of
universal rules or mechanisms that underlie these systems when they are
inherently driven by so many factors which interact in nonlinear and
probabilistic ways?

The difficulty of inferring the mechanisms that drive any complex system are
twofold: 1) deciding on the best spatial, temporal, and organizational scale at
which to model a process and 2) determining which the best set of models and
parameters explain a particular dataset collected at that scale. Innumerable
biological mechanisms have been posited at various spatial, temporal, and
organizational scales (@fig:slices). How does one decide the best scale at which
to model a processes, or at what scale it is best to look for universality?


![Conceptual space with three axes.](./figures/tensorslices.png){#fig:slices}

@Lawton1999 argues that as an organizational scale, the ecology community is
frought with too many "contingencies" in order to find universality. Partially
in response to Lawton's paper, the metacommunity framework [@Leibold2003MetCom]
sought to address the inherently spatial nature of metacommunity processes.
@Vellend2010ConSyn posits four fundamental processes, analogous to evolutionary
genetics. @Poisot2015BeySpe also notes the importance of variation in traits and
abundance.  Necessary additional spatial and temporal dimension to community
processes. The scales at which we propose mechanisms are subject to selection
bias based on the data we can collect---looking for lost keys where the light is
better.


What is in this paper? We argue that advances in computational resources and
methods for likelihood-free inference put us in the place where  simulation
models can enable us to test more complex interaction mechanisms [@Cranmer]. Prediction as
a measure of model efficacy. Dynamical systems perspective on metacommunity
ecology.

How do we predict how ecosystems will change at the scale of community ecology?
The mechanisms that influence the dynamics of communities are multifaceted.
@Vellend2010ConSyn proposes four fundamental mechanisms of community ecology:
speciation, selection, drift, and dispersal. The metacommunity concept
[@Leibold2003MetCom] provides a framework to understand how species interact,
how they are distributed across space, and how their changes through time. This
enables conceptual synthesis of evolutionary (trait drift and selection in
response to both the environment and other species) and ecological (species
interacting with oneanother and their environment) processes.
Many ecological and evolutionary processes fall within the metacommunity
construction. How does species respond to variation and change in the
environment? How does the composition of ecosystems (species) respond to
evolutionary processes, which form the species pool?

ScientificML [@Rackauckas2020UniDif].

The data we collect from these systems is inherently noisy. This data contains
information produced by a combination of the amalgamation of "true" ecological
and evolutionary mechanisms (interacting in unknown ways) compounded by sampling
biases. We first need to ask if we can understand the mechanisms producing these
phenomena, which we argue is synonymous with prediction. The second question
then becomes can we forecast/manage these systems? Example of success in
climate/weather forecasting.

# A dynamical systems perspective on ecological mechanisms

Dynamical systems is the subfield of mathematics related to systems that change
over time.

Often by applying a geometric perspective to state-space.
What is state space?

***What is an ecological mechanism?***
A mechanism describes how the state of a system changes from one timestep to
the next.  
A mapping between low dimensional latent/parameter space and information space.

Why is simulation necessary in ecology? They allow us to produce data that
encodes explicit mechanism [@Crutchfield1992SemThe].


***Metacommunity states and mechanisms***
Within this abstraction, a metacommunity state is a set of measurements for
species across locations at a single point in time, which can be represented as
a matrix: a grid of measurements where each row corresponds to location and each
column to species.

***Metacommunity dynamics and tensors***
Across timepoints, a set of states form trajectories which can
be represented as a a tensor.

![A mechanism is a flow on the state space.](./figures/flows.png){#fig:flow}



# Using simulation to infer mechanisms in ecology

Simulation models have a long history in ecology.
However, fitting these models to data has proven difficult for a variety of reasons.
High-dimensional model with little data. Further 

Brief mention of ABC.
Discuss other likelihood-free methods.

![Likelihood free inference for metacommunity ecology ](./figures/likelihoodfreeinference.png){#fig:information}


# Predictive ecology as a scientific epistemology

What scales are inherently more predictable.

Here we propose that simulation models have the potential to infer
This results in the question: what are the mechanisms best describe a set of data?

Science is fundamentally a theory of epistemology: a methodology and set of
principles to make justified claims about the world. Descriptive claims about
the world (the Earth goes around the sun, more species are found near the
equator than far from it) are considered justified if they make predictions that
agree with observed reality. In order to determine if a descriptive claim agrees
with reality, it must be translated into a quantitative model that makes
predictions about things that can be measured. These quantitative models take
many forms. A subclass of these models, mechanistic models, represent latent
processes that can not be observed or measured, either inherently or due to
technological limitations.


> The electron is a theory we use; it is so useful in understanding the way
nature works that we can almost call it real.
>
> Richard P. Feynman



Different levels of conceptual abstraction have
proven successful in predicting how biological systems change over time.


Still, predicting how ecosystems will change in the future remains a fundamental
goal of ecology.

There is variation in the what scales are best for prediction
[@Brodie2021ExpTim], and some forms of dynamics are intrinsically complex enough
to avoid effective prediction at all [@Pennekamp2019IntPre; @Beckage2011LimPre;
@Chen2019RevCom].


# Conclusion



What does is mean for a model to be correct?
Take the logistic model, for example. Although
logistic growth is observed in many model and to some degree non-model systems, it is hard to say there is some intrinsic truth to this--i.e. that logistic growth is an ecoloigical "law". The phenomena of population dynamics are the result of
individual organisms being born, reproducing, and dying at a lower level of organization, but the logistic model is a useful abstraction under some circumstances.


It is useful the notion that a model represents some "truth" about the world,
instead models have vary in their usefulness. predictive accuracy is  one
measure of this usefulness. The problem is you cannot tell the difference
---Hume and the induction problem.

If a simulation makes data the looks like real data, does it represent the
"true" world? Does it matter? Newtonian Gravity was "right", until GR was more
right. Different models at different levels of abstract provide varying levels
of predictive accuracy. Mechanisms that are incorrect that produce information
that shares statistical properties with empirical data can still be useful.


***What are the limitations of the utility of mechanistic simulations***
There are limits to the scope of simulation models. How do we know when they
are appropriate, versus a ML/non-mechanistic model?

Need for flexible set of tools to do this, setting up the next chapter.



# References
