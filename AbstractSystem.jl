function calc_norm(array :: Matrix{Float64})
  sqrt(sumabs2(array) / size(array, 1))
end

function calc_norm(vector :: Array{Float64, 1})
  sqrt(sumabs2(vector))
end

function restriction(vector)
  vector / (calc_norm(vector) + 0.001)
end

function init(a...)
    restriction(randn(a...))
end

const DefaultRate = 0.01

immutable Class
    class_name :: String
    type_len :: Int64
end

function Base.show(io :: IO, m :: Class)
    print(io, string("Class(", m.class_name, ")"))
end

immutable Object
    obj_name :: String
    class :: Class
    value :: Array{Float64, 1}
end

Object(obj_name :: String, class :: Class) = Object(obj_name, class, init(class.type_len))

function Base.show(io :: IO, m :: Object)
    print(io, string("Obj(", m.obj_name, "){", m.class.class_name, "}"))
end

type DFunction
    func_name :: String
    in_classes :: Array{Class, 1}
    out_class :: Class
    f_matrix :: Matrix{Float64}
    f_transformation :: Transformation
    learning_rate :: Float64
end

function Base.show(io :: IO, m :: DFunction)
    in_names = join([c.class_name for c in m.in_classes], ",")
    print(io, string("Func(", m.func_name, "){", in_names, "->", m.out_class.class_name, "}"))
end

function LFunction(func_name, in_classes :: Array{Class, 1}, out_class :: Class, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(func_name, in_classes, out_class, init(out_len, in_len), Identity, learning_rate)
end

function SFunction(func_name, in_classes :: Array{Class, 1}, out_class :: Class, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(func_name, in_classes, out_class, init(out_len, in_len), Sigmoid, learning_rate)
end

function DFunction(func_name, in_classes :: Array{Class, 1}, out_class :: Class, f_transformation = Sigmoid, learning_rate = DefaultRate)
    in_len = sum([class.type_len for class in in_classes])
    out_len = out_class.type_len
    DFunction(func_name, in_classes, out_class, init(out_len, in_len), f_transformation, learning_rate)
end

function CoFunction(func_name, in_class :: Class, f_transformation = Sigmoid)
    DFunction(func_name, [in_class], in_class, diagm(ones(in_class.type_len)), f_transformation, 0.0)
end

function apply(func :: DFunction, objs :: Array{Object, 1})
    inputs = vcat([obj.value for obj in objs]...)
    outputs = eval(func.f_transformation).(func.f_matrix * inputs)
    Object("untitled", func.out_class, outputs)
end

function apply!(func :: DFunction, in_objs :: Array{Object, 1}, out_obj :: Object)
    inputs = vcat([obj.value for obj in in_objs]...)
    out_obj.value .= eval(func.f_transformation).(func.f_matrix * inputs)
end