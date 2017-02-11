
using JLD
include("Transformation.jl")
include("AbstractSystem.jl")
include("Tree.jl")
include("Evaluation.jl")
include("BackPropogation.jl")
include("Facility.jl")
import Base.push!

type Axiom
    tree1 :: Tree
    tree2 :: Tree
    index :: Dict
end

function Base.show(io :: IO, m :: Axiom)
    print(io, "Axiom[")
    print(io, m.tree1)
    print(io, ", ")
    print(io, m.tree2)
    print(io, "]")
end

function beautify(m :: Axiom)
    string("Axiom:\n", beautify(m.tree1, 1), "\n", beautify(m.tree2, 1), "\n")
end

Axiom(tree1 :: Tree, tree2 :: Tree) = Axiom(tree1, tree2, add!(index(tree1), index(tree2)))

Axiom(skeleton1, skeleton2) = Axiom(toTree(skeleton1), toTree(skeleton2))

function push!(index :: Dict, ops :: Array)
    n = length(ops)
    for i in 1:n
        for t in index[i]
            t.op = ops[i]
        end
    end
end

function push!(index :: Dict, ops :: Dict)
    for key in keys(ops)
        if haskey(index, key)
            ts = index[key]
            for t in ts
                t.op = ops[key]
            end
        end
    end
end

function push!(axiom :: Axiom, ops)
    push!(axiom.index, variables)
end

function init_axiom!(axiom :: Axiom, variables)
    push!(axiom.index, variables)
    init_tree!(axiom.tree1)
    init_tree!(axiom.tree2)
end

init_axioms! = distribute(init_axiom!)

## add some loss function to deal with degenerating problem?

function loss(a, b)
    b * (1. - a * b)
end

function train_axiom!(axiom :: Axiom, variables, n = 1, randomize = identity)
    push!(axiom.index, variables)
    d1 :: Array{Float64, 1} = axiom.tree1.value[:d]
    d2 :: Array{Float64, 1} = axiom.tree2.value[:d]
    v1 :: Array{Float64, 1} = axiom.tree1.value[:value]
    v2 :: Array{Float64, 1} = axiom.tree2.value[:value]
    for i in 1:n
        randomize(variables)
        push!(axiom.index, variables)
        eval_tree!(axiom.tree2)
        eval_tree!(axiom.tree1)
        for j in 1:length(d1)
            d1[j] = loss(v1[j], v2[j])
            d2[j] = loss(v2[j], v1[j])
        end
        bp_tree!(axiom.tree1)
        bp_tree!(axiom.tree2)
    end
end

train_axioms! = distribute(train_axiom!)

## to prevent degeneration problem, we use anti-traing to deal with the problem.

function anti_train_axiom!(axiom :: Axiom, n = 1, randomize = identity)
    d1 :: Array{Float64, 1} = axiom.tree1.value[:d]
    d2 :: Array{Float64, 1} = axiom.tree2.value[:d]
    v1 :: Array{Float64, 1} = axiom.tree1.value[:value]
    v2 :: Array{Float64, 1} = axiom.tree2.value[:value]
    for i in 1:n
        randomize(axiom.tree1)
        randomize(axiom.tree2)
        eval_tree!(axiom.tree2)
        eval_tree!(axiom.tree1)
        for j in 1:length(d1)
            d1[j] = - loss(v1[j], v2[j])
            d2[j] = - loss(v2[j], v1[j])
        end
        bp_tree!(axiom.tree1)
        bp_tree!(axiom.tree2)
    end
end

anti_train_axioms! = distribute(anti_train_axiom!)

include("DataStructs.jl")

@load "infinity.jld"

## The Repl facility, note that for the program structure parsing, we rely on the julia parser;
## and we also need to read the variable name from string.
include("Repl.jl")
r = REPL(Env.empty, Seq.empty)

a1 = repl(r, "function(x) x end").value;
a2 = repl(r, "var y = function(x) x end").value;
a3 = repl(r, "y").value;
a4 = repl(r, "function(x) x(x) end").value;
a5 = repl(r, "begin var y = function(x) x end; y end").value;
as = [a1, a2, a3, a4, a5];

pair_computation(function(x, y) sum(abs(as[x] - as[y])) end, 1:5)
