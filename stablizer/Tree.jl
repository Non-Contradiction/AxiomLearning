type Tree
    op
    value
    subtrees :: Array{Tree, 1}
end

function Base.show(io :: IO, m :: Tree)
    if length(m.subtrees) > 0
        print(io, "[")
    end
    print(io, string(m.op))
    if length(m.subtrees) > 0
        print(io, ", ")
    end
    subs = join([string(subm) for subm in m.subtrees], ", ")
    print(io, subs)
    if length(m.subtrees) > 0
        print(io, "]")
    end
end

function beautify(m :: Tree, indent :: Int64)
    indentation = join(["    " for i in 1:indent])
    string(indentation, m.op, "\n", join([beautify(sub, indent + 1) for sub in m.subtrees]))
end

beautify(m :: Tree) = beautify(m, 0)

pprint(m) = print(beautify(m))

function bottom_up(func :: Function, tree :: Tree)
    func(tree, [bottom_up(func, t) for t in tree.subtrees])
end

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
    ind = Dict{Any, Any}(tree.op => [tree])
    for ind1 in inds
        add!(ind, ind1)
    end
    ind
end

index(tree :: Tree) = bottom_up(_index, tree)