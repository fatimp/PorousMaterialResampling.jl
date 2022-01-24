function create_manifest(stream,
                         prefix :: AbstractString,
                         amount :: Integer,
                         ratio  :: Rational)
    dict = Dict("prefix"      => prefix,
                "amount"      => amount,
                "numerator"   => numerator(ratio),
                "denominator" => denominator(ratio))
    JSON.print(stream, dict, 4)
end

function create_archive(outname :: AbstractString,
                        slices  :: AbstractArray{Bool, 3},
                        ratio   :: Rational)
    prefix = slice_prefix(outname)
    amount = size(slices, 3)

    ZipFile.Writer(outname) do root
        manifest = ZipFile.addfile(root, datafile("manifest.json"), method = ZipFile.Deflate)
        create_manifest(manifest, prefix, amount, ratio)

        for k in 1:amount
            slice = slices[:,:,k]
            name  = datafile("$(prefix)-$(k).png")
            pic   = ZipFile.addfile(root, name, method = ZipFile.Deflate)
            # Here use another IO stream because ZipFile does not work
            # well with FileIO. Julia cannot into abstractions.
            tmpio = IOBuffer()
            save(Stream{format"PNG"}(tmpio), Gray.(slice))
            write(pic, take!(tmpio))
        end
    end

    return
end

function var"archive-w/-nth"(data    :: AbstractArray{Bool, 3},
                             outname :: AbstractString,
                             n       :: Int)
    @assert iszero(rem(size(data, 3), n))
    slices = data[:,:,1:n:end]

    return create_archive(outname, slices, n//1)
end

function var"archive-w/o-nth"(data    :: AbstractArray{Bool, 3},
                              outname :: AbstractString,
                              n       :: Int)
    @assert iszero(rem(size(data, 3), n))
    orig_ratio = n // (n - 1)
    slices = reduce(stich, data[:,:,k] for k in 1:size(data,3) if !iszero(mod(k, n)))

    return create_archive(outname, slices, orig_ratio)
end

archive(data, outname, n, :: Val{:take}) =
    var"archive-w/-nth"(data, outname, n)

archive(data, outname, n, :: Val{:drop}) =
    var"archive-w/o-nth"(data, outname, n)

archive(data, outname, n, mode :: Symbol) =
    archive(data, outname, n, Val(mode))
