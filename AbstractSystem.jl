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
