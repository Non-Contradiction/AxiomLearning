## UChar = Class("Char", 8)
## Stream = List(UChar, Variable, [:v, :u, :v1])

function readBin(x :: Char)
    if x == '0'
        -1.0
    else
        1.0
    end
end
    
function readChar(char_int :: UInt8)
    Object("u", UChar, [readBin(x) for x in bin(char_int, 8)])
end

function readVar(xs :: Array{UInt8,1})
    if length(xs) == 0
        Stream.empty
    else
        apply(Stream.cons, [readChar(xs[1]), readVar(xs[2:end])])
    end
end

function readVar(xs)
    readVar(string(xs).data)
end

function prog(x :: Symbol)
    [var, readVar(x)]
end

function prog(x :: Expr)
    if x.head == :local
        [definition, readVar(x.args[1].args[1]), prog(x.args[1].args[2])]
    elseif x.head == :(=)
        [assignment, readVar(x.args[1]), prog(x.args[2])]
    elseif x.head == :function
        [procedure, readVar(x.args[1].args[1]), prog(x.args[2])]
    elseif x.head == :call
        [func_call, prog(x.args[1]), prog(x.args[2])]
    elseif x.head == :block
        [Seq.cons, prog(x.args[1]), prog(x.args[2:end])]
    else
        Seq.empty
    end
end

function prog(x :: Array)
    if length(x) == 0
        Seq.empty
    else
        [Seq.cons, prog(x[1]), prog(x[2:end])]
    end
end

type REPL
    env :: Object
    ans :: Object
end

function repl(r :: REPL, command :: String)
    command = replace(command, "var ", "local ")
    t = toTree(prog(parse(command)))
    init_tree!(t)
    eval_tree!(t)
    o = Object("c", Prog, t.value[:value])
    r.ans = apply(f_eval, [o, r.env])
    apply!(s_eval, [o, r.env], r.env)
    r.ans
end
