function bp_transformation!(transformation, inputs, d, new_d)
    new_d .= deriv(transformation).(inputs)
    for i in 1:length(d)
        new_d[i] *= d[i]
    end
end

function bp_matrix!(inputs, matrix, d, step, new_d)
    ## step = 0.01
    ## dmatrix = reshape(d, (length(d), 1)) * reshape(inputs, (1, length(inputs)))
    ## matrix[:, :] += step * reshape(d, (length(d), 1)) * reshape(inputs, (1, length(inputs)))
    for j in 1:size(matrix, 2)
        new_d[j] = 0.0
        for i in 1:size(matrix, 1)
            matrix[i, j] += step * d[i] * inputs[j]
            new_d[j] += matrix[i, j] * d[i]
        end
    end
end

function bp_function!(op :: DFunction, value :: Dict)
    bp_transformation!(op.f_transformation, value[:pre_transform], value[:d], value[:pre_transform_d])
    bp_matrix!(value[:pre_matrix], op.f_matrix, value[:pre_transform_d], op.learning_rate, value[:pre_matrix_d])
end

function bp_tree!(tree :: Tree)
    if typeof(tree.op) == DFunction
        bp_function!(tree.op, tree.value)
        for i in 1:length(tree.subtrees)
            tree.subtrees[i].value[:d] .= tree.value[:input_ds][i]
            bp_tree!(tree.subtrees[i])
        end
        ## ds = lens_split(d, [c.feature_len for c in tree.op.in_classes])
        ## for i in 1:length(tree.subtrees)
        ##     bp_tree!(tree.subtrees[i], tree.value[:ds][i])
        ## end
        ## dds = map(bp_class!, tree.op.in_classes, [t.value for t in tree.subtrees], tree.value[:ds])
        ## foreach(bp_tree!, tree.subtrees, dds)
    end
end