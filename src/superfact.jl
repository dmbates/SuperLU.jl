function (\)(A::NCMat,B::DMat)
    perm_r = zeros(Cint,5)
    perm_c = zeros(Cint,5)
    opts = superlu_options_t()
    opts.ColPerm = NATURAL
    stat = [SuperLUStat_t()]
    L = [SuperMatrix()]
    U = [SuperMatrix()]
    BB = [B.smpt]
    info = zeros(Cint,1)
    ccall((:dgssv,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Ptr{Cint},Ptr{Cint},
           Ptr{SuperMatrix},Ptr{SuperMatrix},Ptr{SuperMatrix},
           Ptr{SuperLUStat_t},Ptr{Cint}),
          &opts,&A.smpt,perm_c,perm_r,L,U,BB,stat,info)
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
    stat = [SuperLUStat_t()]
    L = [SuperMatrix()]
    U = [SuperMatrix()]
    perm_c = zeros(Cint,n)
    perm_r = zeros(Cint,m)
    etree = zeros(Cint,n)
    info = zeros(Cint,1)
    ccall((:dgstrf,:libsuperlu),Void,
          (Ptr{superlu_options_t},Ptr{SuperMatrix},Cint,Cint,Ptr{Cint},
           Ptr{Void},Cint,Ptr{Cint},Ptr{Cint},Ptr{SuperMatrix},Ptr{SuperMatrix},
           Ptr{SuperLUStat_t},Ptr{Cint}),
          &opts,&(A.smpt),sp_ienv(2),sp_ienv(1),etree,
          convert(Ptr{Void},0),0,perm_c,perm_r,L,U,stat,info)
    println("info = ",info[1])
    info[1] == 0 || error("dgstrf returned error code $(info[1])")
    ccall((:StatPrint,:libsuperlu),Void,(Ptr{SuperLUStat_t},),stat)
    ccall((:dPrint_CompCol_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "U", &U)
    ccall((:dPrint_SuperNode_Matrix,:libsuperlu),Void,
          (Ptr{Uint8},Ptr{SuperMatrix}), "L", &L)
    showall(perm_c)
    showall(perm_r)
end
