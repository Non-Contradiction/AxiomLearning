Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor, Sensor, Action], Action)
apply(act, [sensor, sensor, action])

Sensor = Class(100)
sensor = Object(Sensor)
Action = Class(120)
action = Object(Action)
act = DFunction([Sensor, Action], Action)
tree = Tree(act, Dict(), [Tree(sensor, Dict(), []), Tree(action, Dict(), [])])
init_tree!(tree)
eval_tree!(tree).value[:value] - apply(act, [sensor, action]).value

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
