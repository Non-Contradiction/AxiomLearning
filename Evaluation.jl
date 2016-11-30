function lens_split(x :: Array, lens :: Array{Int64, 1})
    ind = cumsum(lens)
    n = length(ind)
    ind = [0; ind]
    [view(x, (ind[i]+1):ind[i+1]) for i in 1:n]
end

function init_node!(op :: Object, value :: Dict)
    value[:value] = Array{Float64, 1}(op.class.type_len)
    value[:d] = Array{Float64, 1}(op.class.type_len)
end

function init_node!(op :: DFunction, value :: Dict)
    value[:pre_matrix] = Array{Float64, 1}(size(op.f_matrix, 2))
    value[:pre_transform] = Array{Float64, 1}(op.out_class.type_len)
    value[:value] = Array{Float64, 1}(op.out_class.type_len)
    value[:inputs] = lens_split(value[:pre_matrix], [c.type_len for c in op.in_classes])
    value[:d] = Array{Float64, 1}(op.out_class.type_len)
    value[:pre_transform_d] = Array{Float64, 1}(op.out_class.type_len)
    value[:pre_matrix_d] = Array{Float64, 1}(size(op.f_matrix, 2))
    value[:input_ds] = lens_split(value[:pre_matrix_d], [c.type_len for c in op.in_classes])
end

function _init_tree!(tree :: Tree, _)
    init_node!(tree.op, tree.value)
    tree
end

function init_tree!(tree :: Tree)
    bottom_up(_init_tree!, tree)
end

function eval_node!(op :: Object, value :: Dict, value_list)
    value[:value] .= op.value
end

function eval_node!(op :: DFunction, value :: Dict, value_list)
    i = 1
    for v in value_list
        value[:inputs][i] .= v[:value]
        i += 1
    end
    ## value[:pre_matrix] .= vcat([v[:post_feature] for v in value_list]...)
    A_mul_B!(value[:pre_transform], op.f_matrix, value[:pre_matrix])
    value[:value] .= eval(op.f_transformation).(value[:pre_transform])
end

function _eval_tree!(tree :: Tree, _)
    eval_node!(tree.op, tree.value, (t.value for t in tree.subtrees))
    tree
end

## function eval_tree!(tree :: Tree)
##     bottom_up(_eval_tree!, tree)
## end

function eval_tree!(tree :: Tree)
    foreach(eval_tree!, tree.subtrees)
    eval_node!(tree.op, tree.value, (t.value for t in tree.subtrees))
    tree
end
