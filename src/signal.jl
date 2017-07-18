macro cxo(x, y)
    ts(crossover(data[x.args[1]].values, data[y.args[1]].values), data.index)
end

macro cxu(x, y)
    ts(crossunder(data[x.args[1]].values, data[y.args[1]].values), data.index)
end

macro eq(x, y)
    ts(data[x.args[1]].values .== data[y.args[1]].values, data.index)
end

macro neq(x, y)
    ts(data[x.args[1]].values .!= data[y.args[1]].values, data.index)
end

macro gt(x, y)
    ts(data[x.args[1]].values .> data[y.args[1]].values, data.index)
end

macro lt(x, y)
    ts(data[x.args[1]].values .< data[y.args[1]].values, data.index)
end

macro gte(x, y)
    ts(data[x.args[1]].values .>= data[y.args[1]].values, data.index)
end

macro lte(x, y)
    ts(data[x.args[1]].values .<= data[y.args[1]].values, data.index)
end

immutable Signal
    logic::Expr
    name::Symbol
end

function parse_logic(expr::Expr)::String
    calc = string(expr.args[1])
    ante = string(eval(expr.args[2]))
    post = string(eval(expr.args[3]))
    if calc == "@cxo"
        return "$ante crosses over $post"
    elseif calc == "@cxu"
        return "$ante crosses under $post"
    elseif calc == "@eq"
        return "$ante equals $post"
    elseif calc == "@neq"
        return "$ante is not equal to $post"
    elseif calc == "@gt"
        return "$ante is greater than $post"
    elseif calc == "@lt"
        return "$ante is less than $post"
    elseif calc == "@gte"
        return "$ante is greater than or equal to $post"
    elseif calc == "@lte"
        return "$ante is less than or equal to $post"
    end
end

function show(io::IO, sig::Signal)
    print(io, "$(parse_logic(sig.logic)) --> $(sig.name)")
end

function compute_signal(sig::Signal, data::TS)::TS
    out = eval(sig.logic)
    out.fields[1] = sig.name
    return out
end

