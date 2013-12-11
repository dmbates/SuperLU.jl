module TestNCMat
    using Base.Test
    using SuperLU
                                        # test matrix from SuperLU Users' Guide
    A = NCMat(sparse(Int32[1,2,5,1,3,5,1,3,1,4,4,5],
                     Int32[1,1,1,2,2,2,3,3,4,4,5,5],
                     [19.,12,12,21,12,12,21,16,21,5,21,18]))
    B = DMat(ones(5))
    perm_r = zeros(Cint,5)
    perm_c = zeros(Cint,5)
    opts = SuperLU.superlu_options_t()
    opts.ColPerm = SuperLU.NATURAL
    stat = [SuperLU.SuperLUStat_t()]
    L = [SuperLU.SuperMatrix()]
    U = [SuperLU.SuperMatrix()]
    AA = [A.smpt]
    BB = [B.smpt]
    info = zeros(Cint,1)
    ccall((:dgssv,:libsuperlu),Void,
          (Ptr{SuperLU.superlu_options_t},Ptr{SuperLU.SuperMatrix},Ptr{Cint},Ptr{Cint},
           Ptr{SuperLU.SuperMatrix},Ptr{SuperLU.SuperMatrix},Ptr{SuperLU.SuperMatrix},
           Ptr{SuperLU.SuperLUStat_t},Ptr{Cint}),
          &opts,&A.smpt,perm_c,perm_r,L,U,BB,stat,info)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperLU.SuperMatrix}), "U", &U)
    ccall((:dPrint_SuperNode_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperLU.SuperMatrix}), "L", &L)
    showall(perm_c)
    showall(perm_r)
end
