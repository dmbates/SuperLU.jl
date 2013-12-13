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

nnz(A::NCformat) = A.nnz
nnz(A::NRformat) = A.nnz
nnz(A::SCformat) = A.nnz
nnz(A::SCPformat) = A.nnz
nnz(A::NCPformat) = A.nnz
nnz(A::DNformat) = A.nnz
nnz(A::NRformat_loc) = A.nnz
function matstore(A::SuperMatrix)
    st = Stype(A)
    st == SLU_NC && return unsafe_pointer_to_objref(convert(Ptr{NCformat},A.Store))
    st == SLU_NCP && return unsafe_pointer_to_objref(convert(Ptr{NCPformat},A.Store))
    st == SLU_NR && return unsafe_pointer_to_objref(convert(Ptr{NRformat},A.Store))
    st == SLU_SC && return unsafe_pointer_to_objref(convert(Ptr{SCformat},A.Store))
    st == SLU_SCP && return unsafe_pointer_to_objref(convert(Ptr{SCPformat},A.Store))
    st == SLU_SR && return unsafe_pointer_to_objref(convert(Ptr{SRformat},A.Store))
    st == SLU_DN && return unsafe_pointer_to_objref(convert(Ptr{DNformat},A.Store))
    st == SLU_NR_loc && return unsafe_pointer_to_objref(convert(Ptr{NRformat_loc},A.Store))
    error("Unknown Stype = $st")
end

nnz(A::SuperLUMat) = A.sm.Store == zero(Ptr{Void}) ? zero(Cint) : nnz(matstore(A))

function NCMat(A::SparseMatrixCSC{Cdouble})
    m,n = map(int32,size(A))
    AA = issym(A) ? ltri(A) : A
    mtyp = issym(A) ? SLU_SYL : (istril(A) ? SLU_TRL : (istriu(A) ? SLU_TRU : SLU_GE))
    nz = int32(nnz(AA)); nzval = copy(AA.nzval); rv = AA.rowval; cp = AA.colptr
    rowind = Array(int_t,nz); colptr = Array(int_t,n+i1)
                                        # use zero-based indices
    for i in 1:length(rowind); rowind[i] = int32(rv[i]) - i1; end
    for i in 1:length(colptr); colptr[i] = int32(cp[i]) - i1; end
    cres = nv(SuperMatrix)
    ccall((:dCreate_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Cint,Ptr{Cdouble},Ptr{Cint},Ptr{Cint},Stype_t,Dtype_t,Mtype_t),
          &cres,m,n,nz,nzval,rowind,colptr,SLU_NC,SLU_D,mtyp)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),
          "A", &cres)
    NCMat(cres,colptr,rowind,nzval)
end

function DMat(B::StridedVecOrMat{Cdouble})
    m = int32(size(B,1)); n = int32(size(B,2))
    mtyp = isa(B, Vector) ? SLU_GE : (istril(B) ? SLU_TRL : (istriu(B) ? SLU_TRU : SLU_GE))
    nzval = copy(B[:])
    cres = nv(SuperMatrix)
    ccall((:dCreate_Dense_Matrix,:libsuperlu),Void,
          (Ptr{SuperMatrix},Cint,Cint,Ptr{Cdouble},Cint,Cint,Cint,Cint),
          &cres,size(B,1),size(B,2),B,stride(B,2),SLU_DN,SLU_D,mtyp)
    ccall((:dPrint_Dense_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),
          "B", &cres)
    DMat(cres,nzval)
end

## Extract compiled-in sizes from libsuperlu
function sp_ienv(i::Integer)
    0 < i < 8 || error("i must be in 1,2,...,7")
    ccall((:sp_ienv,:libsuperlu),Cint,(Cint,),i)
end

function (\)(A::NCMat,B::DMat)
    opts = nv(superlu_options_t)
    m,n = size(A); m == n == size(B,1) || error("Dimension mismatch")
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
          &opts,&A.sm,perm_c,perm_r,&L,&U,&B.sm,&sTat,inFo)
    info[1] == 0 || error("dgssv returned error code $(info[1])")
    ccall((:StatPrint,:libsuperlu),Void,(Ptr{SuperLUStat_t},),stat)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "U", &U)
    ccall((:dPrint_SuperNode_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "L", &L)
    showall(perm_c)
    showall(perm_r)
    reshape(B.nzval,size(B))
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

