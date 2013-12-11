## Automatically generated using the following and then hand-edited to
## remove duplicates and coerce constants to the appropriate type.

## using Clang.wrap_c
## context = wrap_c.init(; output_file="superlu_h.jl",
##                       header_library=x->"/usr/include/superlu",
##                       header_wrapped=(x,y)->contains(y, "superlu"),
##                       clang_diagnostics=true,
##                       clang_args=["-v"])
## context.options.wrap_structs = true
## wrap_c.wrap_c_headers(context, ["/usr/include/superlu/slu_ddefs.h"])

const EMPTY = int32(-1)
const FALSE = int32(0)
const TRUE = int32(1)

typealias int_t Cint

# begin enum Stype_t
typealias Stype_t Cint   # technically, Uint32 but printing a Cint is less verbose
const SLU_NC = int32(0)
const SLU_NR = int32(1)
const SLU_SC = int32(2)
const SLU_SR = int32(3)
const SLU_NCP = int32(4)
const SLU_DN = int32(5)
# end enum Stype_t

# begin enum Dtype_t
typealias Dtype_t Cint
const SLU_S = int32(0)
const SLU_D = int32(1)
const SLU_C = int32(2)
const SLU_Z = int32(3)
# end enum Dtype_t

# begin enum Mtype_t
typealias Mtype_t Cint
const SLU_GE = int32(0)
const SLU_TRLU = int32(1)
const SLU_TRUU = int32(2)
const SLU_TRL = int32(3)
const SLU_TRU = int32(4)
const SLU_SYL = int32(5)
const SLU_SYU = int32(6)
const SLU_HEL = int32(7)
const SLU_HEU = int32(8)
# end enum Mtype_t

type SuperMatrix
    Stype::Stype_t
    Dtype::Dtype_t
    Mtype::Mtype_t
    nrow::int_t
    ncol::int_t
    Store::Ptr{None}
end

type NCformat
    nnz::int_t
    nzval::Ptr{None}
    rowind::Ptr{int_t}
    colptr::Ptr{int_t}
end

type NRformat
    nnz::int_t
    nzval::Ptr{None}
    colind::Ptr{int_t}
    rowptr::Ptr{int_t}
end
type SCformat
    nnz::int_t
    nsuper::int_t
    nzval::Ptr{None}
    nzval_colptr::Ptr{int_t}
    rowind::Ptr{int_t}
    rowind_colptr::Ptr{int_t}
    col_to_sup::Ptr{int_t}
    sup_to_col::Ptr{int_t}
end
type NCPformat
    nnz::int_t
    nzval::Ptr{None}
    rowind::Ptr{int_t}
    colbeg::Ptr{int_t}
    colend::Ptr{int_t}
end
type DNformat
    lda::int_t
    nzval::Ptr{None}
end

# begin enum yes_no_t
typealias yes_no_t Cint
const NO = int32(0)
const YES = int32(1)
# end enum yes_no_t

# begin enum fact_t
typealias fact_t Cint
const DOFACT = int32(0)
const SamePattern = int32(1)
const SamePattern_SameRowPerm = int32(2)
const FACTORED = int32(3)
# end enum fact_t

# begin enum rowperm_t
typealias rowperm_t Cint
const NOROWPERM = int32(0)
const LargeDiag = int32(1)
const MY_PERMR = int32(2)
# end enum rowperm_t

# begin enum colperm_t
typealias colperm_t Cint
const NATURAL = int32(0)
const MMD_ATA = int32(1)
const MMD_AT_PLUS_A = int32(2)
const COLAMD = int32(3)
const MY_PERMC = int32(4)
# end enum colperm_t

# begin enum trans_t
typealias trans_t Cint
const NOTRANS = int32(0)
const TRANS = int32(1)
const CONJ = int32(2)
# end enum trans_t

# begin enum DiagScale_t
typealias DiagScale_t Cint
const NOEQUIL = int32(0)
const ROW = int32(1)
const COL = int32(2)
const BOTH = int32(3)
# end enum DiagScale_t

# begin enum IterRefine_t
typealias IterRefine_t Cint
const NOREFINE = int32(0)
const SINGLE = int32(1)
const DOUBLE = int32(2)
const EXTRA = int32(3)
# end enum IterRefine_t

# begin enum MemType
typealias MemType Cint
const LUSUP = int32(0)
const UCOL = int32(1)
const LSUB = int32(2)
const USUB = int32(3)
# end enum MemType

# begin enum stack_end_t
typealias stack_end_t Cint
const HEAD = int32(0)
const TAIL = int32(1)
# end enum stack_end_t

typealias LU_space_t Cint
const SYSTEM = int32(0)
const USER = int32(1)
# end enum LU_space_t

# begin enum PhaseType
typealias PhaseType Cint
const COLPERM = int32(0)
const RELAX = int32(1)
const ETREE = int32(2)
const EQUIL = int32(3)
const FACT = int32(4)
const RCOND = int32(5)
const SOLVE = int32(6)
const REFINE = int32(7)
const TRSV = int32(8)
const GEMV = int32(9)
const FERR = int32(10)
const NPHASES = int32(11)
# end enum PhaseType

typealias flops_t Cfloat
typealias Logical Cuchar
type superlu_options_t
    Fact::fact_t
    Equil::yes_no_t
    ColPerm::colperm_t
    Trans::trans_t
    IterRefine::IterRefine_t
    PrintStat::yes_no_t
    SymmetricMode::yes_no_t
    DiagPivotThresh::Cdouble
    PivotGrowth::yes_no_t
    ConditionNumber::yes_no_t
    RowPerm::rowperm_t
    ReplaceTinyPivot::yes_no_t
    SolveInitialized::yes_no_t
    RefineInitialized::yes_no_t
end
type SuperLUStat_t
    panel_histo::Ptr{Cint}
    utime::Ptr{Cdouble}
    ops::Ptr{flops_t}
    TinyPivots::Cint
    RefineSteps::Cint
end
type GlobalLU_t
    xsup::Ptr{Cint}
    supno::Ptr{Cint}
    lsub::Ptr{Cint}
    xlsub::Ptr{Cint}
    lusup::Ptr{Cdouble}
    xlusup::Ptr{Cint}
    ucol::Ptr{Cdouble}
    usub::Ptr{Cint}
    xusub::Ptr{Cint}
    nzlmax::Cint
    nzumax::Cint
    nzlumax::Cint
    n::Cint
    MemModel::LU_space_t
end
type mem_usage_t
    for_lu::Cfloat
    total_needed::Cfloat
    expansions::Cint
end
