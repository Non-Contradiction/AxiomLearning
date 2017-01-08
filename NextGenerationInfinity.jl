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
    b - a
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

## To prevent degeneration problem, we use anti-training to deal with the problem.
## The current method to deal with degeneration is anti-training: to push random evaluation results far away,
## but the defect now is that it is unstable in long term.
## One possible remedy is to anti-train only when the random evaluation results are "too near".

const DefaultThreshold = 0.1

function anti_train_axiom!(axiom :: Axiom, n = 1, randomize = identity, thres = DefaultThreshold)
    d1 :: Array{Float64, 1} = axiom.tree1.value[:d]
    d2 :: Array{Float64, 1} = axiom.tree2.value[:d]
    v1 :: Array{Float64, 1} = axiom.tree1.value[:value]
    v2 :: Array{Float64, 1} = axiom.tree2.value[:value]
    for i in 1:n
        randomize(axiom.tree1)
        randomize(axiom.tree2)
        eval_tree!(axiom.tree2)
        eval_tree!(axiom.tree1)
        if mean((v1 - v2) .^ 2) < thres
            for j in 1:length(d1)
                d1[j] = - loss(v1[j], v2[j])
                d2[j] = - loss(v2[j], v1[j])
            end
            bp_tree!(axiom.tree1)
            bp_tree!(axiom.tree2)
        end
    end
end

anti_train_axioms! = distribute(anti_train_axiom!)

include("DataStructs.jl")

UChar = Class("Char", 8)
Variable = Class("Variable", 100)
Stream = List(UChar, Variable, [:v, :u, :v1])

Prog = Class("Prog", 100)
Bindingc = Class("Binding", 100)
Binding = Pair(Variable, Prog, Bindingc, [:b, :v, :p])

Framec = Class("Frame", 100)
Frame = List(Bindingc, Framec, [:f1, :b, :f2])

Envc = Class("Env", 200)
Env = List(Framec, Envc, [:e1, :f, :e2])

lookup = DFunction("lookup", [Envc, Variable], Prog)
set = DFunction("set", [Envc, Variable, Prog], Envc)
add_binding = DFunction("add_binding", [Framec, Variable, Prog], Framec)
def = DFunction("def", [Envc, Variable, Prog], Envc)
extend = DFunction("extend", [Envc, Variable, Prog], Envc)

var = DFunction("var", [Variable], Prog)
definition = DFunction("definition", [Variable, Prog], Prog) 
assignment = DFunction("assignment", [Variable, Prog], Prog) 
procedure = DFunction("procedure", [Variable, Prog], Prog)
func_call = DFunction("func_call", [Prog, Prog], Prog)
Seq = List(Prog, Prog)

f_eval = DFunction("f_eval", [Prog, Envc], Prog)
s_eval = DFunction("eval", [Prog, Envc], Envc)

@load "infinity.jld"

Interpreter = Dict()
I_names = Dict()
I_names[:base] = [:UChar, :Variable, :Stream, :Prog, :Bindingc, :Binding, :Framec, :Frame, :Envc, :Env]
I_names[:env] = [:lookup, :set, :add_binding, :def, :extend]
I_names[:prog] = [:var, :definition, :assignment, :procedure, :func_call, :Seq]
I_names[:repl] = [:f_eval, :s_eval]
inject(I_names, Interpreter)
Interpreter

axiom_lookup1 = Axiom([lookup, [Env.cons, [Frame.cons, [Binding.pair, :v, :p], :f], :e], :v], :p)
axiom_lookup2 = Axiom([lookup, [Env.cons, [Frame.cons, [Binding.pair, :v1, :p1], :f2], :e2], :v2], 
                      [lookup, [Env.cons, :f2, :e2], :v2])
axiom_lookup3 = Axiom([lookup, [Env.cons, Frame.empty, :e], :v], [lookup, :e, :v])

axiom_set1 = Axiom([set, [Env.cons, [Frame.cons, [Binding.pair, :v1, :p1], :f2], :e2], :v1, :p2], 
                   [Env.cons, [Frame.cons, [Binding.pair, :v1, :p2], :f2], :e2])
axiom_set2 = Axiom([set, [Env.cons, [Frame.cons, [Binding.pair, :v1, :p1], :f2], :e2], :v2, :p2], 
                   [Env.cons, [Frame.cons, [Binding.pair, :v1, :p1], 
                                           [Env.first, [set, [Env.cons, :f2, :e2], :v2, :p2]]], 
                              [Env.rest, [set, [Env.cons, :f2, :e2], :v2, :p2]]])
axiom_set3 = Axiom([set, [Env.cons, Frame.empty, :e], :v, :p], [Env.cons, Frame.empty, [set, :e, :v, :p]])

axiom_add_binding = Axiom([add_binding, :f, :v, :p], [Frame.cons, [Binding.pair, :v, :p], :f])
axiom_def = Axiom([def, :e, :v, :p], [Env.first!, :e, [add_binding, [Env.first, :e], :v, :p]])
axiom_extend = Axiom([extend, :e, :v, :p], [def, [Env.cons, Frame.empty, :e], :v, :p])

axiom_var_s = Axiom([s_eval, [var, :v], :e], :e)
axiom_var_f = Axiom([f_eval, [var, :v], :e], [lookup, :e, :v])
axiom_definition_s = Axiom([s_eval, [definition, :v, :p], :e], [def, [s_eval, :p, :e], :v, [f_eval, :p, :e]])
axiom_definition_f = Axiom([f_eval, [definition, :v, :p], :e], [f_eval, :p, :e])
axiom_assignment_s = Axiom([s_eval, [assignment, :v, :p], :e], [set, [s_eval, :p, :e], :v, [f_eval, :p, :e]])
axiom_assignment_f = Axiom([f_eval, [assignment, :v, :p], :e], [f_eval, :p, :e])
axiom_proc_s = Axiom([s_eval, [procedure, :v, :p], :e], :e)
axiom_proc_f = Axiom([f_eval, [procedure, :v, :p], :e], [procedure, :v, :p])
axiom_func_s1 = Axiom([s_eval, [func_call, :p1, :p2], :e], 
                      [s_eval, [func_call, [f_eval, :p1, :e], [f_eval, :p2, :e]], :e])
axiom_func_f1 = Axiom([f_eval, [func_call, :p1, :p2], :e], 
                      [f_eval, [func_call, [f_eval, :p1, :e], [f_eval, :p2, :e]], :e])
axiom_func_s2 = Axiom([s_eval, [func_call, [procedure, :v, :p1], :p2], :e], 
                      [Env.rest, [s_eval, :p1, [extend, :e, :v, :p2]]])
axiom_func_f2 = Axiom([f_eval, [func_call, [procedure, :v, :p1], :p2], :e], [f_eval, :p1, [extend, :e, :v, :p2]])
axiom_seq_s = Axiom([s_eval, [Seq.cons, :p1, :p2], :e], [s_eval, :p2, [s_eval, :p1, :e]])
axiom_seq_f = Axiom([f_eval, [Seq.cons, :p1, :p2], :e], [f_eval, :p2, [s_eval, :p1, :e]])

axioms = Dict()
axioms_lookup = [axiom_lookup1, axiom_lookup2, axiom_lookup3]
axioms_set = [axiom_set1, axiom_set2, axiom_set3]
axioms[:base_env] = [Stream.axioms, Binding.axioms, Frame.axioms, Env.axioms]
axioms[:env] = [axioms_lookup, axioms_set, axiom_add_binding, axiom_def, axiom_extend]
axioms_v = [axiom_var_s, axiom_var_f]
axioms_d = [axiom_definition_s, axiom_definition_f]
axioms_a = [axiom_assignment_s, axiom_assignment_f]
axioms_p = [axiom_proc_s, axiom_proc_f]
axioms_f = [axiom_func_s1, axiom_func_f1, axiom_func_s2, axiom_func_f2]
axioms_s = [axiom_seq_s, axiom_seq_f]
axioms[:prog] = [axioms_v, axioms_d, axioms_a, axioms_p, axioms_f, axioms_s];

## The Repl facility, note that for the program structure parsing, we rely on the julia parser;
## and we also need to read the variable name from string.
include("Repl.jl")
r = REPL(Env.empty, Seq.empty)

function object_init(dict :: Dict, name, num :: Int64, class :: Class)
    dict[Symbol(name, num)] = Object(string(name, num), class)
end

function object_init(dict :: Dict, name, class :: Class)
    dict[Symbol(name)] = Object(string(name), class)
end

function object_init(dict :: Dict, name_dict :: Dict, num :: Int64)
    for k in keys(name_dict)
        object_init(dict, k, name_dict[k])
        for i in 1:num
            object_init(dict, k, i, name_dict[k])
        end
    end
end

function object_init(dict :: Dict, name_dict :: Dict)
    for k in keys(name_dict)
        object_init(dict, k, name_dict[k])
    end
end

type Memory
    class :: Class
    mclass :: Class
    
    encode :: DFunction
    decode :: DFunction
    
    axioms :: Array{Axiom, 1}
end

function Base.show(io :: IO, m :: Memory)
    print(io, string("Module.Memory(", m.class.class_name, "->", m.mclass.class_name, ")"))
end

function Memory(class :: Class, mclass :: Class, symbols = [:s, :m])
    encode = DFunction("encode", [class], mclass)
    decode = DFunction("decode", [mclass], class)
    
    sym = symbols[1]
    msym = symbols[2]
    axiom1 = Axiom([decode, [encode, sym]], sym)
    axiom2 = Axiom([encode, [decode, msym]], msym)
    axioms = [axiom1, axiom2]
    
    Memory(class, mclass, encode, decode, axioms)
end

function Memory(class :: Class, type_len :: Int64, symbols = [:s, :m])
    memory_name = string("Memory", "_", class.class_name)
    mclass = Class(memory_name, type_len)
    Memory(class, mclass, symbols)
end

## @time l = List(Sensor, 70)

naive_randomize = distribute(function(o :: Object) randn!(o.value) end)

function another_naive_randomize(tree :: Tree)
    foreach(another_naive_randomize, tree.subtrees)
    if typeof(tree.op) == Object
        randn!(tree.op.value)
    end
    tree
end

# UChar = Class("Char", 8)
# Variable = Class("Variable", 100)
# Prog = Class("Prog", 100)
# Bindingc = Class("Binding", 100)
# Binding = Pair(Variable, Prog, Bindingc, [:b, :v, :p])
# Framec = Class("Frame", 100)
# Frame = List(Bindingc, Framec, [:f1, :b, :f2])
# Envc = Class("Env", 200)
# Env = List(Framec, Envc, [:e1, :f, :e2])

dict = Dict()
ndict = Dict()
ndict[:u] = UChar
ndict[:v] = Variable
ndict[:p] = Prog
ndict[:b] = Bindingc
ndict[:f] = Framec
ndict[:e] = Envc
object_init(dict, ndict, 2)

init_axioms!(axioms, dict)
while true
    anti_train_axioms!(axioms, 1000, another_naive_randomize)
    train_axioms!(axioms, dict, 10000, naive_randomize)
    save("infinity.jld", Interpreter)
end
