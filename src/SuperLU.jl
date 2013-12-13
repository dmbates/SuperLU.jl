module SuperLU

    import Base: \, lufact, size, nnz

    export
        DMat,
        NCMat,
        superlu_options_t,
        SuperLUStat_t,
        SuperMatrix,
        nv,
        sp_ienv

    include("superlu_h.jl")
    include("superlu_types.jl")
    include("SuperLUCode.jl")

end # module
