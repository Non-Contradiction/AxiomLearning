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
