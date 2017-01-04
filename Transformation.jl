immutable Transformation
    self :: Function
    deriv :: Function
end

function Base.show(io :: IO, m :: Transformation)
    print(io, string("Transformation(", m.self, ")"))
end

import Core.eval

function eval(transformation :: Transformation)
    transformation.self
end

function deriv(transformation :: Transformation)
    transformation.deriv
end

function sigmoid(x)
        2. / (1. + exp(-x)) - 1.
end

function dsigmoid(x)
    2. * exp(-x) / (1. + exp(-x)) ^ 2
end

const Sigmoid = Transformation(sigmoid, dsigmoid)

const Identity = Transformation(identity, one) 