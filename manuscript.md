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
question, even in abstract, proves difficult. How can we determine if there is
some set of universal rules or mechanisms that underlie systems driven by many
factors which interact in nonlinear and probabilistic ways across separate
organizational scales? We propose that this problem can be split into two parts:
1) deciding on the best spatial, temporal, and organizational scale at which to
model an ecosystem process, and 2) after a particular scale has been chosen,
determining the best model at that scale and associated parameters that explain
a particular dataset.

The first question is to determine the proper scale to model a given system.
Innumerable biological mechanisms have been posited at various spatial,
temporal, and organizational scales (@fig:slices). How does one decide the best
scale at which to model a processes, or at what scale it is best to look for
universality?

@LevinsLewontin write

> The problem for science is to understand the proper domain of explanation of
> each abstraction rather than become its prisoner.

The second question is, after a given scale is selected, to select the best model
from a set of competing models at that scale.
This question is primarily implicated with prediction---that is, what model best
predicts ecological systems at a particular scale?
This has applied need as forecasting is an imperative in ecology.
Some scales are more predictable than others.

![Conceptual space with three axes.](./figures/tensorslices.png){#fig:slices}


@Lawton1999 argues that as an organizational scale, the ecological
community is frought with too many "contingencies" to find
universality. **TODO -- more details on the variability of processes in community ecology***



Partially in response to Lawton's paper, many conceputal
frameworks have been proposed to incorporate processes across multiple scales.

The metacommunity framework [@Leibold2003MetCom] sought to address the inherently spatial nature
of metacommunity processes. @Vellend2010ConSyn posits four fundamental
processes, analogous to evolutionary genetics. @Poisot2015BeySpe also notes the
importance of variation in traits and abundance.  Necessary additional spatial
and temporal dimension to community processes. The scales at which we propose
mechanisms are subject to selection bias based on the data we can
collect---looking for lost keys where the light is better.


The data we collect from ecological systems is inherently noisy. This data
contains information produced by a combination of the amalgamation of "true"
ecological and evolutionary mechanisms (interacting in unknown ways) compounded
by sampling biases.

What is in this paper? We argue that advances in computational resources and
methods for likelihood-free inference put us in the place where generative
models can enable us to test more complex interaction mechanisms [@Cranmer2020FroSim]. We
present a conceptual framework for determining the best model from a set of
competing simulation models. We then present an example where we fit data from
empirical food webs from Mangal [@cite] to various generative models of
food-web structure. We then infer parameters via ABC. Then we apply generative
models to test set to see which makes best predictions about interactions.


 ScientificML [@Rackauckas2020UniDif].


# Using simulation models for ecological inference

Simulation models have a long history in ecology. cite some examples.

Still, fitting simulation models to data is difficult.
^what does this mean to someone who doesn't know what fitting means

No likelihood function.
General problem of high-dimensional model, compounded by little data.

What is enabling this now? computational capacity and methods for optimization
parameter estimation. More data.

![Likelihood free inference for metacommunity ecology ](./figures/likelihoodfreeinference.png){#fig:information}


# Case study: predicting ecological networks using generative learning

***We need to talk about summary statistics***

Is proportion more "predictable" than individual occupancy?

Which ones make effective predictions? What models do we use to fit empirical
data to simulated (generative adversarial networks, MCMC-ABC methods, etc.)
Caveats on more complex models for this simple example.
Refer to up-to-date resources on model fitting an assessment.

# Predictive ecology as a scientific epistemology

What scales are inherently more predictable.

Here we propose that simulation models have the potential to infer
This results in the question: what are the mechanisms best describe a set of data?

Science is fundamentally a theory of epistemology: a methodology and set of
principles to make justified claims about the world. Descriptive claims about
the world (the Earth goes around the sun, more species are found near the
equator than far from it) are considered justified if they make predictions that
agree with observed reality.

> The sciences do not try to explain, they hardly even try to interpret,
> they mainly make models. By a model is meant a mathematical construct
> which, with the addition of certain verbal interpretations, describes
> observed phenomena. The justification of such a mathematical construct
> is solely and precisely that it is expected to work - that is correctly
> to describe phenomena from a reasonably wide area. Furthermore, it must
> satisfy certain esthetic criteria - that is, in relation to how much it
> describes, it must be rather simple.
>
> John Von Neumann

> The electron is a theory we use; it is so useful in understanding the way
nature works that we can almost call it real.
>
> Richard P. Feynman


The whole idea of searching for "laws" (Lawton) rests on an assumption that there
are universal

All models are wrong is not just about statistical models.

In order to determine if a descriptive claim agrees
with reality, it must be translated into a quantitative model that makes
predictions about things that can be measured. These quantitative models take
many forms. A subclass of these models, mechanistic models, represent latent
processes that can not be observed or measured, either inherently or due to
technological limitations.




Different levels of conceptual abstraction have
proven successful in predicting how biological systems change over time.

Still, predicting how ecosystems will change in the future remains a fundamental
goal of ecology.

There is variation in the what scales are best for prediction
[@Brodie2021ExpTim], and some forms of dynamics are intrinsically complex enough
to avoid effective prediction at all [@Pennekamp2019IntPre; @Beckage2011LimPre;
@Chen2019RevCom].


# Conclusion

What does is mean for a model to be correct? Take the logistic model, for
example. Although logistic growth is observed in many model and to some degree
non-model systems, it is hard to say there is some intrinsic truth to this--i.e.
that logistic growth is an ecoloigical "law". The phenomena of population
dynamics are the result of individual organisms being born, reproducing, and
dying at a lower level of organization, but the logistic model is a useful
abstraction under some circumstances.

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


# old stuff

**A state-space perspective on ecological mechanisms**

In order to present the conceptual framework for simulation-based inference,
we first need to propose some definitions. This conceptual framework
is based around consider the _dynamics_ of a metacommunity system by considering
the _geometry_ of how that system changes in _state-space_.


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




# References
