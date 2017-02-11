type Pair
    class1 :: Class
    class2 :: Class
    pclass :: Class
    
    pair :: DFunction
    first :: DFunction
    second :: DFunction
    first! :: DFunction
    second! :: DFunction
    
    axioms :: Array{Axiom, 1}
end

function Base.show(io :: IO, m :: Pair)
    print(io, string("Module.Pair(", m.class1.class_name, ",", m.class2.class_name, "->", m.pclass.class_name, ")"))
end

function Pair(class1 :: Class, class2 :: Class, pclass :: Class, symbols = [:xy, :x, :y])
    pair = DFunction("pair", [class1, class2], pclass)
    first = DFunction("first", [pclass], class1)
    second = DFunction("second", [pclass], class2)
    first! = DFunction("first!", [pclass, class1], pclass)
    second! = DFunction("second!", [pclass, class2], pclass)
    
    tsym = symbols[1]
    fsym = symbols[2]
    ssym = symbols[3]
    axiom_first = Axiom([first, [pair, fsym, ssym]], fsym)
    axiom_second = Axiom([second, [pair, fsym, ssym]], ssym)
    axiom_first! = Axiom([first!, tsym, fsym], [pair, fsym, [second, tsym]])
    axiom_second! = Axiom([second!, tsym, ssym], [pair, [first, tsym], ssym])
    axioms = [axiom_first, axiom_second, axiom_first!, axiom_second!]
    
    Pair(class1, class2, pclass, pair, first, second, first!, second!, axioms)
end

function Pair(class1 :: Class, class2 :: Class, type_len :: Int64, symbols = [:xy, :x, :y])
    post_name = string("_", class1.class_name, "_", class2.class_name)
    pair_name = string("Pair", post_name)
    pclass = Class(pair_name, type_len)
    Pair(class1, class2, pclass, symbols)
end

type List
    class :: Class
    lclass :: Class
    
    empty :: Object

    cons :: DFunction
    first :: DFunction
    rest :: DFunction
    first! :: DFunction
    rest! :: DFunction
    
    axioms :: Array{Axiom, 1}
end

function Base.show(io :: IO, m :: List)
    print(io, string("Module.List(", m.class.class_name, "->", m.lclass.class_name, ")"))
end

function List(class :: Class, lclass :: Class, symbols = [:xxs, :x, :xs])
    empty = Object("empty", lclass)
    empty.value .= -1.
    
    cons = DFunction("cons", [class, lclass], lclass)
    first = DFunction("first", [lclass], class)
    rest = DFunction("rest", [lclass], lclass)
    first! = DFunction("first!", [lclass, class], lclass)
    rest! = DFunction("rest!", [lclass, lclass], lclass)
    
    tsym = symbols[1]
    fsym = symbols[2]
    rsym = symbols[3]
    axiom_first = Axiom([first, [cons, fsym, rsym]], fsym)
    axiom_rest = Axiom([rest, [cons, fsym, rsym]], rsym)
    axiom_first! = Axiom([first!, tsym, fsym], [cons, fsym, [rest, tsym]])
    axiom_rest! = Axiom([rest!, tsym, rsym], [cons, [first, tsym], rsym])
    axioms = [axiom_first, axiom_rest, axiom_first!, axiom_rest!]
    
    List(class, lclass, empty, cons, first, rest, first!, rest!, axioms)
end

function List(class :: Class, type_len :: Int64, symbols = [:xxs, :x, :xs])
    list_name = string("List", "_", class.class_name)
    lclass = Class(list_name, type_len)
    List(class, lclass, symbols)
end
