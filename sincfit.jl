function csinc(y, j, h)
    sinc((y - j * h) / h)
end

function sincgridinds(n)
    if iseven(n)
        error("n must be odd.")
    end
    range(-(n - 1) ÷ 2, (n - 1) ÷ 2, length=n)
end

function sincgrid(n, h)
    return collect(h .* sincgridinds(n))
end

function test_grid_interpole_func(; n = 21, h = 1)
    
    mygrid = sincgrid(21, h)
    myfs = myf.(mygrid)
    x->grideval(x, myfs, csinc, h)
end

function grideval(y, fs, cf, h)
    js = sincgridinds(length(fs))

    mapreduce(+, js, fs) do j, f
        cf(y, j, h) * f
    end
end

# dcsin(y, j, h) = sinc((y-j*h)/h)

function ccsincdelem(i, j, h; T=Float64)
    out = zero(T)
    if i != j
        out = ((h * i - h * j) * pi * cospi(-i + j) + h * sinpi(-i + j)) / ((h * i - h * j)^2 * pi)
    end
    return out
end

function ccsincd(y::T, j, h) where {T}
    out = zero(T)
    if h * j != y
        out = (pi * (-(h * j) + y) * cos(pi * (j - y / h)) + h * sin(pi * (j - y / h))) / (pi * (-(h * j) + y)^2)
    end
    return out
end

function ccsincdd(y::T, j, h) where {T}
    out::T = -1 / 3 * pi^2 / h^2
    if h * j != y
        out = (2 * h * pi * (-(h * j) + y) * cos(pi * (j - y / h)) - (h^2 * (-2 + j^2 * pi^2) - 2 * h * j * pi^2 * y + pi^2 * y^2) * sin(pi * (j - y / h))) / (h * pi * (h * j - y)^3)
    end
    return out
end


function ccsincddelem(i, j, h; T=Float64)
    out::T = -1 / 3 * pi^2 / h^2
    if i != j
        out = (2 * h * (h * i - h * j) * pi * cospi(-i + j) - (h^2 * i^2 * pi^2 - 2 * h^2 * i * j * pi^2 + h^2 * (-2 + j^2 * pi^2)) * sinpi(-i + j)) / (h * (-(h * i) + h * j)^3 * pi)
    end
    return out
end

# ((h*i - h*j)*Pi*Cos[(-i + j)*Pi] + h*Sin[(-i + j)*Pi])/((h*i - h*j)^2*Pi)
