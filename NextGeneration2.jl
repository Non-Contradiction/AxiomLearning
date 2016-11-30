
immutable Transformation
    self :: Function
    deriv :: Function
end

import Core.eval

function eval(transformation :: Transformation)
    transformation.self
end

function deriv(transformation :: Transformation)
    transformation.deriv
end

function sigmoid(x)
        1. / (1. + exp(-x)) - 0.5
end

function dsigmoid(x)
    exp(-x) / (1. + exp(-x))^2
end

const Sigmoid = Transformation(sigmoid, dsigmoid)

const Identity = Transformation(identity, one)

function calc_norm(array :: Matrix{Float64})
  sqrt(sumabs2(array)/size(array, 1))
end

function calc_norm(vector :: Array{Float64, 1})
  sqrt(sumabs2(vector))
end

function restriction(vector)
  vector / (calc_norm(vector)+0.001)
end

function init(a...)
    restriction(randn(a...))
end

const DefaultRate = 0.01

immutable Class
    type_len :: Int64
end

type Object
    class :: Class
    value :: Array{Float64, 1}
end

Object(class :: Class) = Object(class, init(class.type_len))

type DFunction
    in_classes :: Array{Class, 1}
    out_class :: Class
    f_matrix :: Matrix{Float64}
    f_transformation :: Transformation
    learning_rate :: Float64
end

function LFunction(in_classes :: Array{Class, 1}, out_class :: Class, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(in_classes, out_class, init(out_len, in_len), Identity, learning_rate)
end

function SFunction(in_classes :: Array{Class, 1}, out_class :: Class, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(in_classes, out_class, init(out_len, in_len), Sigmoid, learning_rate)
end

function DFunction(in_classes :: Array{Class, 1}, out_class :: Class, f_transformation = Sigmoid, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(in_classes, out_class, init(out_len, in_len), f_transformation, learning_rate)
end

function CoFunction(in_class :: Class, f_transformation = Sigmoid)
    DFunction([in_class], in_class, diagm(ones(in_class.type_len)), f_transformation, 0.0)
end

function apply(func :: DFunction, objs :: Array{Object, 1})
    inputs = vcat([obj.value for obj in objs]...)
    outputs = eval(func.f_transformation).(func.f_matrix * inputs)
    Object(func.out_class, outputs)
end

function apply!(func :: DFunction, in_objs :: Array{Object, 1}, out_obj :: Object)
    inputs = vcat([obj.value for obj in in_objs]...)
    out_obj.value .= eval(func.f_transformation).(func.f_matrix * inputs)
end

Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor, Sensor, Action], Action)
apply(act, [sensor, sensor, action])

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

Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor, Action], Action)
tree = Tree(act, Dict(), [Tree(sensor, Dict(), []), Tree(action, Dict(), [])])
init_tree!(tree)
eval_tree!(tree).value[:value] - apply(act, [sensor, action]).value

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

Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor, Action], Action)
tree = Tree(act, Dict(), [Tree(sensor, Dict(), []), Tree(action, Dict(), [])])
init_tree!(tree)
d = ones(length(eval_tree!(tree).value[:value])) - eval_tree!(tree).value[:value]
for i in 1:5000
    tree.value[:d] .= ones(length(eval_tree!(tree).value[:value])) - eval_tree!(tree).value[:value]
    bp_tree!(tree)
end
maximum(abs(ones(length(eval_tree!(tree).value[:value])) - eval_tree!(tree).value[:value]))

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

Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor], Action)
invact = DFunction([Action], Sensor)
axiom = Axiom([1, [2, 3]], 3)

@time train!(axiom, [invact, act, sensor], 10000)
@time foreach(i -> eval_tree!(axiom.tree1), 1:10000)
maximum(abs(eval_tree!(axiom.tree2).value[:value] - eval_tree!(axiom.tree1).value[:value]))

Profile.clear()
@profile train!(axiom, [invact, act, sensor], 1000)
## Profile.print()
Profile.print(format = :flat)
