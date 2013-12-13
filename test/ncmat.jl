module TestNCMat
    using Base.Test
    using SuperLU
                                        # test matrix from SuperLU Users' Guide
    a = sparse(Int32[1,2,5,2,3,5,1,3,1,4,4,5],Int32[1,1,1,2,2,2,3,3,4,4,5,5],
               [19.,12,12,21,12,12,21,16,21,5,21,18])
    print(full(a))
    A = NCMat(a)
    B = DMat(ones(5))
    perm_r = zeros(Cint,5)
    perm_c = zeros(Cint,5)
    opts = nv(superlu_options_t)
#    opts.ColPerm = SuperLU.NATURAL
    sTat = nv(SuperLUStat_t)
    L = nv(SuperMatrix)
    U = nv(SuperMatrix)
    inFo = zeros(Cint,1)
    ccall((:dgssv,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Ptr{Cint},Ptr{Cint},
           Ptr{SuperMatrix},Ptr{SuperMatrix},Ptr{SuperMatrix},
           Ptr{SuperLUStat_t},Ptr{Cint}),
          &opts,&(A.sm),perm_c,perm_r,&L,&U,&(B.sm),&sTat,inFo)
    println("info returned by dgssv = ", inFo[1])
    ccall((:StatPrint,:libsuperlu),Void,(Ptr{SuperLUStat_t},),&sTat)
    println("B.nzval after solution")
    showcompact(B.nzval)
    ccall((:dPrint_Dense_Matrix,:libsuperlu),Void,(Ptr{Uint8},Ptr{SuperMatrix}),"X",&(B.sm))
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "U", &U)
    ccall((:dPrint_SuperNode_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "L", &L)
    showall(perm_c)
    println()
    showall(perm_r)
    println()
    sol = pointer_to_array(unsafe_pointer_to_objref(convert(Ptr{SuperLU.DNformat},B.sm.Store)).nzval,5)
end
