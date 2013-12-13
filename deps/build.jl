using BinDeps 

@BinDeps.setup

superlu = library_dependency("libsuperlu")

provides(Sources,URI("http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_4.3.tar.gz"),superlu)
@linux_only begin
    provides(AptGet, "libsuperlu4", superlu)  # created for Debian, not yet on Ubuntu
    provides(Yum, "SuperLU", superlu)
end

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
            error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    superlu = library_dependency("libsuperlu")
    provides( Homebrew.HB, "superlu", superlu, os = :Darwin ) # doesn't exist at present
end

@BinDeps.install
