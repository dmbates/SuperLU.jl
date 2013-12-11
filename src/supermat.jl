## constructors of null versions of types for passing to C
const d0 = zero(Cdouble)
const i0 = zero(int_t)
const i1 = one(int_t)

const dnull = convert(Ptr{Cdouble},0)
const fnull = convert(Ptr{flops_t},0)
const inull = convert(Ptr{int_t},0)
const nnull = convert(Ptr{None},0)

SuperMatrix() = SuperMatrix(SLU_NC,SLU_D,SLU_GE,i0,i0,nnull)
NCformat() = NCformat(i0,nnull,inull,inull)
NRformat() = NRformat(i0,nnull,inull,inull)
SCformat() = SCformat(i0,i0,nnull,inull,inull,inull,inull,inull)
NCPformat() = NCPformat(i0,nnull,inull,inull,inull)
DNformat() = DNformat(i0,nnull)

function superlu_options_t()
    res = superlu_options_t(i0,i0,i0,i0,i0,i0,i0,d0,i0,i0,i0,i0,i0,i0)
    ccall((:set_default_options,:libsuperlu),Void,(Ptr{superlu_options_t},),&res)
    res
end

function SuperLUStat_t()
    res = SuperLUStat_t(inull,dnull,fnull,i0,i0)
    ccall((:StatInit,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&res)
    res
end

abstract SuperLUMat

size(A::SuperLUMat,d::Integer) = d == 1 ? A.smpt.nrow : (d == 2 ? A.smpt.ncol : 1)
size(A::SuperLUMat) = (A.smpt.nrow,A.smpt.ncol)

## Modify this for {T<:Union(Float64,Complex128)}
type NCMat <: SuperLUMat                # sparse matrix in compressed-column format
    smpt::SuperMatrix
    colptr::Vector{int_t}
    rowind::Vector{int_t}
    nzval::Vector{Cdouble}
end

function NCMat(A::SparseMatrixCSC{Cdouble})
    m,n = map(int32,size(A))
    AA = issym(A) ? ltri(A) : A
    mtyp = issym(A) ? SLU_SYL : (istril(A) ? SLU_TRL : (istriu(A) ? SLU_TRU : SLU_GE))
    nz = int32(nnz(AA)); nzval = copy(AA.nzval); rv = AA.rowval; cp = AA.colptr
    rowind = Array(int_t,nz); colptr = Array(int_t,n+i1)
                                        # use zero-based indices
    for i in 1:length(rowind); rowind[i] = int32(rv[i]) - i1; end
    for i in 1:length(colptr); colptr[i] = int32(cp[i]) - i1; end
    cres = SuperMatrix()
    ccall((:dCreate_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Cint,Ptr{Cdouble},Ptr{Cint},Ptr{Cint},Stype_t,Dtype_t,Mtype_t),
          &cres,m,n,nz,nzval,rowind,colptr,SLU_NC,SLU_D,mtyp)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),
          "A", &cres)
    NCMat(cres,colptr,rowind,nzval)
end

type DMat <: SuperLUMat                 # dense matrix
    smpt::SuperMatrix
    nzval::Vector{Cdouble}
end

function DMat(B::StridedVecOrMat{Cdouble})
    m = int32(size(B,1)); n = int32(size(B,2))
    mtyp = isa(B, Vector) ? SLU_GE : (istril(B) ? SLU_TRL : (istriu(B) ? SLU_TRU : SLU_GE))
    nzval = copy(B[:])
    cres = SuperMatrix()
    ccall((:dCreate_Dense_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Ptr{Cdouble},Cint,Cint,Cint,Cint),
          &cres,m,n,B,stride(B,2),5,1,0)
    ccall((:dPrint_Dense_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),
          "B", &cres)
    DMat(cres,nzval)
end
