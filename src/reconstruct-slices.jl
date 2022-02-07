# Normalized S₂ in spatial domain
s2(x :: AbstractArray{Bool}) =
    (x |> fft .|> abs2 |> ifft |> real) / length(x)

function read_manifest(root)
    manifest = find_file(root, datafile("manifest.json"))
    return JSON.parse(manifest)
end

function create_hints(slices :: AbstractArray{Bool, 3},
                      ratio  :: Rational)
    n, m = numerator(ratio), denominator(ratio)
    x, y, z = size(slices)

    hints = rand(Bool, (x, y, Int(ratio * z)))

    # = Original has each n-th sample
    if m == 1
        for k in 1:z
            hints[:,:,(k-1)*n+1] = slices[:,:,k]
        end
    # = Original has each n-th sample dropped
    elseif n == m + 1
        for k in 1:z
            hints[:,:,(k-1)÷m + k] = slices[:,:,k]
        end
    else
        throw("Hints are not supported for this ratio")
    end

    # KLUDGE: without this magic line the last slice of a
    # reconstructed image will be a noisy mix of the first and the
    # last slice of the original.
    hints[:,:,end] = slices[:,:,end]

    return hints
end

"""
    reconstruct(archivename; radius = 0.6, use_hints = false)

Reconstruct two-phase porous medium from an archive of
slices. `archivename` is the name of the archive. `radius` is a filter
width used in Phase Reconstruction algorithm and the default value is
usually good for all cases. When `use_hints` is `true` the slices are
used not only for creation of autocorrelation function, but also in
initial approximation of the porous medium. This results in a
reconstruction with more visual resemblance with the original.
"""
function reconstruct(archivename :: AbstractString;
                     radius      :: AbstractFloat = 0.6,
                     use_hints   :: Bool          = false)
    local slices, ratio

    ZipFile.Reader(archivename) do root
        manifest = read_manifest(root)

        ratio  = manifest["numerator"] // manifest["denominator"]
        prefix = manifest["prefix"]
        n      = manifest["amount"]

        slices = mapreduce(stich, 1:n) do k
            pic  = find_file(root, datafile("$(prefix)-$(k).png"))
            # Here read all data and wrap in in another IO stream
            # because ZipFile does not work well with FileIO. Julia
            # cannot into abstractions.
            rawdata = Vector{UInt8}(undef, pic.uncompressedsize)
            read!(pic, rawdata)
            rawdata |> IOBuffer |> Stream{format"PNG"} |> load .|> Bool
        end
    end

    # Calculate normalized S₂ function in spatial
    # domain. Normalization means that the result of F¯¹[|F(f)|²] is
    # divided on number of elements in the array.
    s2cut = s2(slices)

    # Resample correlation function along the third dimension. The
    # number of slices in the third dimension is multiplied by ratio.
    s2restored = AutoCorrelationResampling.ac_resample(s2cut, ratio)

    # Transform to unnormalized representation in the frequency
    # domain. Sometimes small negative values may occur after
    # resampling. Just clamp all values to the range [0, ∞).
    s2ft = max.(s2restored |> rfft |> real, 0) * length(s2restored)

    # Create hints if needed
    hints = use_hints ? create_hints(slices, ratio) : nothing
    
    return PhaseRec.phaserec(s2ft, size(s2restored);
                             radius = radius,
                             noise  = hints)
end
