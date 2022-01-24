mydiff(x, y) = mapreduce(abs, +, x - y) / length(x)

run(`unxz -kf sample.raw.xz`)
orig = read_cuboid("sample.raw", 500, 3) |> BitArray

@test mydiff(reconstruct("sample-10.zip"; use_hints = true)[1], orig) < 0.1
@test mydiff(reconstruct("sample-50.zip"; use_hints = true)[1], orig) < 0.05
@test mydiff(reconstruct("sample-90.zip"; use_hints = true)[1], orig) < 0.02
