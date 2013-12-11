function sp_ienv(i::Integer)
    0 < i < 8 || error("i must be in 1,2,...,7")
    ccall((:sp_ienv,:libsuperlu),Cint,(Cint,),i)
end

