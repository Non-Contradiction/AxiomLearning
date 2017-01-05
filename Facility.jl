function distribute(f)
    function fs(dict :: Dict, xs...)
        for i in values(dict)
            fs(i, xs...)
        end
    end
    function fs(arr :: Array, xs...)
        for i in arr
            fs(i, xs...)
        end
    end
    function fs(xs...)
        f(xs...)
    end
    fs
end

function _inject(sym :: Symbol, dict :: Dict)
    dict[string(sym)] = eval(sym)
end

inject = distribute(_inject)

function combination{T}(xs :: Array{T, 1})
    if length(xs) < 2
        []
    elseif length(xs) == 2
        Array{Tuple{T, T}, 1}([(xs[1], xs[2])])
    else
        Array{Tuple{T, T}, 1}([[(xs[1], x) for x in xs[2:end]]..., combination(xs[2:end])...])
    end
end

function combination(xs)
    if length(xs) < 2
        []
    elseif length(xs) == 2
        [(xs[1], xs[2])]
    else
        [[(xs[1], x) for x in xs[2:end]]..., combination(xs[2:end])...]
    end
end

function pair_computation(func :: Function, xs)
    function compute(x)
        print(string("Result for pair ", x[1], " and ", x[2], " is ", func(x[1], x[2]), ".\n"))
    end
    foreach(compute, combination(xs))
end
