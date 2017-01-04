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