module SuperLU

    #using StrPack
    import Base: \, lufact, size, nnz

    export
        DMat,
        NCMat,
        superlu_options_t,
        SuperLUStat_t,
        SuperMatrix,
        sp_ienv

    include("superlu_utils.jl")
    include("superlu_h.jl")
    include("supermat.jl")
    include("superfact.jl")

end # module
