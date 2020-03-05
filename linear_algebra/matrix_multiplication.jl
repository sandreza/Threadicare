using KernelAbstractions, Test, CUDAapi, BenchmarkTools
if CUDAapi.has_cuda_gpu()
    using CuArrays
    CuArrays.allowscalar(false)
end

# Simple kernel for matrix multiplication
@kernel function matmul_kernel!(a, b, c)
    i, j = @index(Global, NTuple)

    # creating a temporary sum variable for matrix multiplication
    tmp_sum = zero(eltype(c))
    for k = 1:size(a)[2]
        tmp_sum += a[i,k] * b[k, j]
    end

    c[i,j] = tmp_sum
end

@kernel function matmul_kernel_2!(a, b, c)
    i, j = @index(Global, NTuple)

    # creating a temporary sum variable for matrix multiplication
    c[i,j] = zero(eltype(c))
    for k = 1:size(a)[2]
        c[i,j] += a[i,k] * b[k, j]
    end

end

# Creating a wrapper kernel for launching with error checks
function matmul!(a, b, c)
    if size(a)[2] != size(b)[1]
        println("Matrix size mismatch!")
        return nothing
    end
    if isa(a, Array)
        kernel! = matmul_kernel!(CPU(),4)
    else
        kernel! = matmul_kernel!(CUDA(),256)
    end
    kernel!(a, b, c, ndrange=size(c))
end

# Creating a wrapper kernel for launching with error checks
function matmul_2!(a, b, c)
    if size(a)[2] != size(b)[1]
        println("Matrix size mismatch!")
        return nothing
    end
    if isa(a, Array)
        kernel! = matmul_kernel_2!(CPU(),4)
    else
        kernel! = matmul_kernel_2!(CUDA(),256)
    end
    kernel!(a, b, c, ndrange=size(c))
end

a = rand(256,123)
b = rand(123, 45)
c = zeros(256, 45)

# beginning CPU tests, returns event
ev = matmul!(a,b,c)
wait(ev)

@test isapprox(c, a*b)

# beginning GPU tests
if has_cuda_gpu()
    d_a = CuArray(a)
    d_b = CuArray(b)
    d_c = CuArray(c)

    ev = matmul!(d_a, d_b, d_c)
    wait(ev)

    @test isapprox(Array(d_c), d_a*d_b)
end
