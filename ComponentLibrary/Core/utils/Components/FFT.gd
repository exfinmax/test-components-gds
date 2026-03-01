class_name FFTHelper

static func swap(arr:Array,i1:int,i2:int) -> Array:
	if arr.size() <= i1 || arr.size() <= i2:
		printerr("数组长度小于交换下标，交换失败")
		return arr
	if i1 == i2:
		return arr
	var temp = arr[i1]
	arr[i1] = arr[i2]
	arr[i2] = temp
	return arr
	
# FFT implementation using iterative Cooley-Tukey radix‑2 algorithm.
#
# Behavior:
#  1. Pads the input array to the next power of two (N) by appending zeros.
#     The returned handle_array will therefore have length N.  This is
#     convenient for convolution or spectral processing, but callers who
#     expect the original length should manually resize the result after
#     an inverse transform.
#  2. Performs the transform in place on a temporary working copy, then
#     copies the N‑element result back into handle_array.  The original
#     data is not preserved after the call.
#  3. The "org" parameter selects direction: 1 for forward, -1 for inverse.
#     The inverse transform additionally divides both real and imaginary
#     components by N to normalize.  For inverse transforms, you may want to
#     trim the output back to the original signal length.
#
# Returns the mutated handle_array for chaining.
static func is_power_of_two(x:int) -> bool:
	return x > 0 and (x & (x - 1)) == 0

static func FFT(handle_array:Array[Complex], org:int = 1) -> Array:
	if org not in [1, -1]:
		printerr("未定义的FFT: org must be 1 or -1")
		return handle_array

	# original length
	var n:int = handle_array.size()
	# if length is not power of two, perform naive DFT/IDFT to avoid
	# misleading padding behavior.  This is O(n^2) but keeps result size = n.
	if not is_power_of_two(n):
		var out:Array[Complex] = []
		out.resize(n)
		for k in range(n):
			var sum:Complex = Complex.new(0.0, 0.0)
			for j in range(n):
				var angle:float = TAU * j * k / n * org
				var w:Complex = Complex.new(cos(angle), sin(angle))
				sum = sum.add(handle_array[j].multiply(w))
			if org == -1:
				sum.real /= n
				sum.imag /= n
			out[k] = sum
		# copy back
		handle_array.resize(n)
		for i in range(n):
			handle_array[i] = out[i]
		return handle_array

	# compute padded length (next power of two)
	var N:int = 1
	while N < n:
		N <<= 1

	# prepare array a with padding
	var a:Array[Complex] = []
	a.resize(N)
	for i in range(N):
		if i < n:
			a[i] = handle_array[i]
		else:
			a[i] = Complex.new(0.0, 0.0)

	# bit‑reversal permutation
	var j:int = 0
	for i in range(1, N):
		var bit:int = N >> 1
		while (j & bit) != 0:
			j ^= bit
			bit >>= 1
		j ^= bit
		if i < j:
			a = swap(a, i, j)

	# main FFT loops
	var len:int = 2
	while len <= N:
		var ang:float = TAU / len * org
		var wlen:Complex = Complex.new(cos(ang), sin(ang))
		for i in range(0, N, len):
			var w:Complex = Complex.new(1.0, 0.0)
			for k in range(len/2):
				var u:Complex = a[i + k]
				var v:Complex = w.multiply(a[i + k + len/2])
				a[i + k] = u.add(v)
				a[i + k + len/2] = u.subtract(v)
				w = w.multiply(wlen)
		len <<= 1

	# scale if inverse transform
	if org == -1:
		for i in range(N):
			a[i].real /= N
			a[i].imag /= N

	# update original array to reflect results
	handle_array.resize(N)
	for i in range(N):
		handle_array[i] = a[i]

	return handle_array

# helper to compute the next power of two >= value
static func next_power_of_two(value:int) -> int:
	var v:int = 1
	while v < value:
		v <<= 1
	return v

# convenience wrapper that computes convolution of two integer arrays using FFT
static func convolve_int_arrays(arr1:PackedInt32Array, arr2:PackedInt32Array) -> PackedInt32Array:
	var len1:int = arr1.size()
	var len2:int = arr2.size()
	var target:int = len1 + len2 - 1
	var N:int = next_power_of_two(target)

	# build complex arrays padded to common length N
	var a:Array[Complex] = []
	var b:Array[Complex] = []
	a.resize(N)
	b.resize(N)
	for i in range(N):
		if i < len1:
			a[i] = Complex.new(float(arr1[i]), 0.0)
		else:
			a[i] = Complex.new(0.0, 0.0)
		if i < len2:
			b[i] = Complex.new(float(arr2[i]), 0.0)
		else:
			b[i] = Complex.new(0.0, 0.0)

	# compute transforms on equal-sized vectors
	a = FFT(a)
	b = FFT(b)
	# multiply pointwise over N
	for i in range(N):
		a[i] = a[i].multiply(b[i])
	# inverse transform
	a = FFT(a, -1)
	# convert back to integers and trim to target length
	var result:PackedInt32Array = []
	result.resize(target)
	for i in range(target):
		result[i] = int(round(a[i].real))
	return result

static func convolve_fast(arr1:PackedInt32Array, arr2:PackedInt32Array) -> PackedInt32Array:

	var n1:int = arr1.size()
	var n2:int = arr2.size()
	var target_len:int = n1 + n2 - 1

	var N:int = 1
	while N < target_len:
		N <<= 1

	# ---- 打包两个数组 ----
	var c:Array[Complex] = []
	c.resize(N)

	for i in range(N):
		var real:float = arr1[i] if i < n1 else 0.0
		var imag:float = arr2[i] if i < n2 else 0.0
		c[i] = Complex.new(real, imag)

	# ---- 只做一次 FFT ----
	FFT(c)

	# ---- 频域拆分并相乘 ----
	var result_freq:Array[Complex] = []
	result_freq.resize(N)

	for k in range(N):
		var j:int = (N - k) % N

		var ck:Complex = c[k]
		var cj:Complex = c[j].conjugate()

		var a1:Complex = (ck.add(cj)).multiply(Complex.new(.5))
		var b1:Complex = (ck.subtract(cj)).multiply(Complex.new(0,-.5))
		

		result_freq[k] = a1.multiply(b1)


	# ---- IFFT ----
	FFT(result_freq, -1)

	# ---- 转整数 ----
	var result:PackedInt32Array = []
	result.resize(target_len)

	for i in range(target_len):
		result[i] = int(round(result_freq[i].real))

	return result
