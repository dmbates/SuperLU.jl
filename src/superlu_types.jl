abstract SuperLUMat

## Modify this for {T<:Union(Float64,Complex128)}
type NCMat <: SuperLUMat                # sparse matrix in compressed-column format
    sm::SuperMatrix
    colptr::Vector{int_t}
    rowind::Vector{int_t}
    nzval::Vector{Cdouble}
end

type DMat <: SuperLUMat                 # dense matrix
    sm::SuperMatrix
    nzval::Vector{Cdouble}
end
