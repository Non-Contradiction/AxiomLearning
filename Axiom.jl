function toTree(op)
    Tree(op, Dict(), [])
end

function toTree(skeleton :: Array)
    op = skeleton[1]
    subs = skeleton[2:end]
    Tree(op, Dict(), [toTree(s) for s in subs])
end

function add!(dict :: Dict, dict1 :: Dict)
    for key in keys(dict1)
        dict[key] = vcat(get!(dict, key, []), dict1[key])
    end
    dict
end

function _index(tree :: Tree, inds :: Array)
    ind = Dict(tree.op => [tree])
    for ind1 in inds
        add!(ind, ind1)
    end
    ind
end

index(tree :: Tree) = bottom_up(_index, tree)

type Axiom
    tree1 :: Tree
    tree2 :: Tree
    index :: Dict
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

function train!(axiom :: Axiom, variables, n = 1)
    push!(axiom.index, variables)
    init_tree!(axiom.tree1)
    init_tree!(axiom.tree2)
    d1 :: Array{Float64, 1} = axiom.tree1.value[:d]
    d2 :: Array{Float64, 1} = axiom.tree2.value[:d]
    v1 :: Array{Float64, 1} = axiom.tree1.value[:value]
    v2 :: Array{Float64, 1} = axiom.tree2.value[:value]
    for i in 1:n
        eval_tree!(axiom.tree2)
        eval_tree!(axiom.tree1)
        for j in 1:length(d1)
                d1[j] = v2[j] - v1[j]
                d2[j] = -d1[j]
        end
        bp_tree!(axiom.tree1)
        bp_tree!(axiom.tree2)
    end
end
