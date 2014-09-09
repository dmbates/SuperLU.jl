## constructors of null versions of types for passing to C
for T in (:SuperMatrix,:NCformat,:NRformat,:SCformat,:SCPformat,:NCPformat,
          :DNformat,NRformat_loc,:e_node,:ExpHeader,:LU_stack_t,
          :mem_usage_t,:GlobalLU_t)
    @eval begin
        nv{}(::Type{$T}) = apply($T,map(zero,$T.types))  # null type T value
    end
end

function nv(::Type{superlu_options_t})
    v = apply(superlu_options_t,map(zero,superlu_options_t.types))
    ccall((:set_default_options,:libsuperlu),Void,(Ptr{superlu_options_t},),&v)
    v
end

function nv(::Type{SuperLUStat_t})
    v = apply(SuperLUStat_t,map(zero,SuperLUStat_t.types))
    ccall((:StatInit,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&v)
    v
end

size(A::SuperLUMat,d::Integer) = d == 1 ? A.sm.nrow : (d == 2 ? A.sm.ncol : 1)
size(A::SuperLUMat) = (A.sm.nrow,A.sm.ncol)

Stype(A::SuperMatrix) = A.Stype # storage type (compressed column, dense, etc. - see Stype_t)
Dtype(A::SuperMatrix) = A.Dtype # data type (Cdouble, complex, etc. - see Dtype_t)
Mtype(A::SuperMatrix) = A.Mtype # matrix type (general, tril, triu, sym, etc. - see Mtype_t)

for T in (:NCformat,:NRformat,:SCformat,:SCPformat,:NCPformat,:DNformat,:NRformat_loc)
    @eval begin
        countnz(A::$T) = A.nnz
    end
end

function matstore(A::SuperMatrix)
    st = Stype(A)
    st == SLU_NC && return unsafe_load(convert(Ptr{NCformat},A.Store))
    st == SLU_NCP && return unsafe_load(convert(Ptr{NCPformat},A.Store))
    st == SLU_NR && return unsafe_load(convert(Ptr{NRformat},A.Store))
    st == SLU_SC && return unsafe_load(convert(Ptr{SCformat},A.Store))
    st == SLU_SCP && return unsafe_load(convert(Ptr{SCPformat},A.Store))
    st == SLU_SR && return unsafe_load(convert(Ptr{SRformat},A.Store))
    st == SLU_DN && return unsafe_load(convert(Ptr{DNformat},A.Store))
    st == SLU_NR_loc && return unsafe_load(convert(Ptr{NRformat_loc},A.Store))
    error("Unknown Stype = $st")
end

## could cheat here because nnz is always the first member of the type
countnz(A::SuperLUMat) = A.sm.Store == zero(Ptr{Void}) ? zero(Cint) : countnz(matstore(A))

function NCMat(A::SparseMatrixCSC{Cdouble})
    m,n = map(int32,size(A));
    ## turns out that you can't pass a matrix stored in symmetric form to dgssv
    ## symA = issym(A); AA = symA ? tril(A) : A
    ## mtyp = symA ? SLU_SYL : (istril(A) ? SLU_TRL : (istriu(A) ? SLU_TRU : SLU_GE))
    nz = int32(nfilled(A)); nzval = copy(A.nzval); rv = A.rowval; cp = A.colptr
    rowind = Array(int_t,nz); colptr = Array(int_t,n+i1)
                                        # use zero-based indices
    for i in 1:length(rowind); rowind[i] = int32(rv[i]) - i1; end
    for i in 1:length(colptr); colptr[i] = int32(cp[i]) - i1; end
    cres = nv(SuperMatrix)
    ccall((:dCreate_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Cint,Ptr{Cdouble},Ptr{Cint},Ptr{Cint},Stype_t,Dtype_t,Mtype_t),
          &cres,m,n,nz,nzval,rowind,colptr,SLU_NC,SLU_D,SLU_GE)
#    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),"A",&cres)
    NCMat(cres,colptr,rowind,nzval)
end

function DMat(B::StridedVecOrMat{Cdouble})
    mtyp = isa(B, Vector) ? SLU_GE : (istril(B) ? SLU_TRL : (istriu(B) ? SLU_TRU : SLU_GE))
    nzval = copy(B[:])
    cres = nv(SuperMatrix)
    ccall((:dCreate_Dense_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Ptr{Cdouble},Cint,Cint,Cint,Cint),
          &cres,size(B,1),size(B,2),pointer(nzval),stride(B,2),SLU_DN,SLU_D,mtyp)
#    ccall((:dPrint_Dense_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),"B",&cres)
    DMat(cres,nzval)
end

## Extract compiled-in sizes from libsuperlu
function sp_ienv(i::Integer)
    0 < i < 8 || error("i must be in 1,2,...,7")
    ccall((:sp_ienv,:libsuperlu),Cint,(Cint,),i)
end

function (\)(A::NCMat,B::StridedVecOrMat)
    A.sm.Dtype == SLU_D && eltype(B) == Cdouble || error("Both A and B must be Float64 arrays")
    m,n = size(A); m == n == size(B,1) || error("Dimension mismatch")
    BB = DMat(B)
    opts = nv(superlu_options_t)
    perm_r = zeros(Cint,n)
    perm_c = zeros(Cint,n)
    sTat = nv(SuperLUStat_t)
    L = nv(SuperMatrix)
    U = nv(SuperMatrix)
    inFo = zeros(Cint,1)
    ccall((:dgssv,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Ptr{Cint},Ptr{Cint},
           Ptr{SuperMatrix},Ptr{SuperMatrix},Ptr{SuperMatrix},
           Ptr{SuperLUStat_t},Ptr{Cint}),
          &opts,&A.sm,perm_c,perm_r,&L,&U,&BB.sm,&sTat,inFo)
    inFo[1] == 0 || error("dgssv returned error code $(inFo[1])")
#    ccall((:StatPrint,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&sTat)
    ccall((:StatFree,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&sTat)
    U.Stype == SLU_NC || error("Matrix U should be of type NCformat (Stype = 0)")
    ccall((:Destroy_CompCol_Matrix,:libsuperlu),Void,(Ptr{SuperMatrix},),&U)
    L.Stype == SLU_SC || error("Matrix L should be of type SCformat (Stype = 3)")
    ccall((:Destroy_SuperNode_Matrix,:libsuperlu),Void,(Ptr{SuperMatrix},),&L)
    reshape(BB.nzval,size(B))
end

function lufact(A::NCMat,opts::superlu_options_t)
    m,n = size(A)
    perm_c = zeros(Cint,n)
                                        # determine fill-reducing permutation
    ccall((:get_perm_c,:libsuperlu),Void,(Cint,Ptr{SuperMatrix},Ptr{Cint}),
          opts.ColPerm,&(A.sm),perm_c)
    AC = nv(SuperMatrix)
    eTree = zeros(Cint,n)
                                        # apply perm_c to create AC and form eTree
    ccall((:sp_preorder,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Ptr{Cint},Ptr{Cint},Ptr{SuperMatrix}),
          &opts,&(A.sm),perm_c,eTree,&AC)
    L = nv(SuperMatrix)
    U = nv(SuperMatrix)
    perm_r = zeros(Cint,m)
    inFo = zeros(Cint,1)
    sTat = nv(SuperLUStat_t)
    ccall((:dgstrf,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Cint,Cint,Ptr{Cint},
           Ptr{Void},Cint,Ptr{Cint},Ptr{Cint},Ptr{SuperMatrix},Ptr{SuperMatrix},
           Ptr{SuperLUStat_t},Ptr{Cint}),
          &opts,&(A.sm),sp_ienv(2),sp_ienv(1),eTree,
          zero(Ptr{Void}),0,perm_c,perm_r,&L,&U,&sTat,inFo)
    println("info = ",inFo[1])
    inFo[1] == 0 || error("dgstrf returned error code $(inFo[1])")
    ccall((:StatPrint,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&sTat)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "U", &U)
    ccall((:dPrint_SuperNode_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "L", &L)
    showall(perm_c)
    showall(perm_r)
end
lufact(A::NCMat) = lufact(A,nv(superlu_options_t))

