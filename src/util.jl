### FIXME: This function must be in ZipFile.jl:
function ZipFile.Writer(thunk :: Function, args...)
    io = ZipFile.Writer(args...)
    try
        thunk(io)
    finally
        close(io)
    end
end

### FIXME: This function must be in ZipFile.jl:
function ZipFile.Reader(thunk :: Function, args...)
    io = ZipFile.Reader(args...)
    try
        thunk(io)
    finally
        close(io)
    end
end

"""
    datafile(name)

Return the name of a file inside the archive with slices.
"""
datafile(name :: AbstractString) = joinpath("data", name)

"""
    slice_prefix(name)

Given the name of the archive `name`, return the name prefix for
slices.
"""
slice_prefix(name :: AbstractString) =
    splitext(splitpath(name)[end])[begin]

function find_file(root :: ZipFile.Reader, name :: AbstractString)
    files = root.files

    pos = findfirst(files) do file
        file.name == name
    end

    return files[pos]
end

"""
    stich(x, y)

Concatenate arrays `x` and `y` along the third axis
"""
stich(x :: AbstractArray{T}, y :: AbstractArray{T}) where T =
    cat(x, y; dims = 3)
