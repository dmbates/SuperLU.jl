## based on functions in the tests directory of the MUMPS package
using Base.Test
using SuperLU

ddx(n) = spdiagm((-ones(n), ones(n)),[0,1],n,n+1)

function getDivGrad(n1,n2,n3)
    Div = hcat(kron(speye(n3),kron(speye(n2),ddx(n1))),
               kron(speye(n3),kron(ddx(n2),speye(n1))),
               kron(ddx(n3),kron(speye(n2),speye(n1))))
    Div*Div';
end

dgcube(n) = getDivGrad(n,n,n)

for n in (8,16,24)
    A = dgcube(n)
    b = randn(size(A,1))
    xumf = A\b
    xslu = NCMat(A)\b
    @test_approx_eq (A*xumf) b
    @test_approx_eq (A*xslu) b    
    gc()
    umftimes = [@elapsed A\b for i in 1:10]
    gc()
    slutimes = [@elapsed NCMat(A)\b for i in 1:10]
    println("Times for solving divgrad system of size $(size(A)), nnz = $(nfilled(A))")
    showcompact(umftimes)
    println()
    showcompact(slutimes)
    println()
    println("UMFPACK: mean = $(mean(umftimes)), median = $(median(umftimes))")
    println("SuperLU: mean = $(mean(slutimes)), median = $(median(slutimes))")    
end
