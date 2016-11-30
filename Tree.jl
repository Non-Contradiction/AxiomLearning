type Tree
    op
    value
    subtrees :: Array{Tree, 1}
end

function _bottom_up(func :: Function, tree :: Tree, dict :: Dict)
    function f()
        func(tree, [_bottom_up(func, t, dict) for t in tree.subtrees])
    end
    get!(f, dict, tree)
end

## bottom_up(func :: Function, tree :: Tree) = _bottom_up(func, tree, Dict())

function bottom_up(func :: Function, tree :: Tree)
    func(tree, [bottom_up(func, t) for t in tree.subtrees])
end
