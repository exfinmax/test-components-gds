extends Node

@export var a:PackedInt32Array
@export var b:PackedInt32Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#perform tests with several data sizes
	for size in [10, 1000, 100000]:
		print("\n-- testing size", size, "--")
		var arr1 = generate_array(size)
		var arr2 = generate_array(size)
		# measure direct convolution
		var t0 = Time.get_ticks_msec()
		#var direct = convol(arr1, arr2)
		var t1 = Time.get_ticks_msec()
		#print("direct conv time (ms):", t1 - t0)
		
		# measure helper FFT convolution
		t0 = Time.get_ticks_msec()
		var fftres = FFTHelper.convolve_int_arrays(arr1, arr2)
		t1 = Time.get_ticks_msec()
		print("fft helper conv time (ms):", t1 - t0)
		
		t0 = Time.get_ticks_msec()
		var ffftres = FFTHelper.convolve_fast(arr1,arr2)
		t1 = Time.get_ticks_msec()
		print("fastfft helper conv time (ms):", t1 - t0)

		# optional verify results match (only for smaller sizes)
		#print("dir with fft match?", direct == fftres)
		print("ffft with fft match?", fftres == ffftres)
		#print("dir wit ffft match?", direct == ffftres)
	# if you want to see contents, uncomment:
	# print("result:", fftres)
	
	
	# also run the original A/B export arrays if set
	if a.size() > 0 and b.size() > 0:
		print("\n-- provided arrays conv --")
		run_single(a,b)

func run_single(arr1:PackedInt32Array, arr2:PackedInt32Array) -> void:
	var test_a:Array[Complex] = IntToComplex(arr1)
	var test_b:Array[Complex] = IntToComplex(arr2)

	# determine common transform size based on convolution length
	var len1:int = arr1.size()
	var len2:int = arr2.size()
	var target:int = len1 + len2 - 1
	var N:int = 1
	while N < target:
		N <<= 1

	# pad both sequences to N
	test_a.resize(N)
	test_b.resize(N)
	for i in range(len1, N):
		test_a[i] = Complex.new(0.0, 0.0)
	for i in range(len2, N):
		test_b[i] = Complex.new(0.0, 0.0)

	# forward FFTs (store returned arrays)
	test_a = FFTHelper.FFT(test_a)
	test_b = FFTHelper.FFT(test_b)

	# multiply pointwise over N
	for i in range(N):
		test_a[i] = test_a[i].multiply(test_b[i])

	# inverse FFT and convert back to integers
	test_a = FFTHelper.FFT(test_a, -1)
	var fft_int:PackedInt32Array = ComplexToInt(test_a)
	# trim to convolution length
	if fft_int.size() > target:
		fft_int.resize(target)
	print("fft result:", fft_int)
	print("direct conv:", convol(arr1,arr2))
	print("helper conv:", FFTHelper.convolve_int_arrays(arr1, arr2))



func IntToComplex(a:PackedInt32Array) -> Array[Complex]:
	var result_array:Array[Complex]
	result_array.resize(a.size())
	for i in range(a.size()):
		result_array[i] = Complex.new(float(a[i]), 0.0)
	return result_array

func ComplexToInt(a:Array[Complex]) -> PackedInt32Array:
	var result_array:PackedInt32Array
	result_array.resize(a.size())
	for i in range(a.size()):
		# round to nearest integer
		result_array[i] = int(round(a[i].real))
	return result_array

func convol(a:PackedInt32Array,b:PackedInt32Array) -> PackedInt32Array:
	var a_num:int = a.size()
	var b_num:int = b.size()
	var lth:int = a_num + b_num - 1
	var result_arr:PackedInt32Array = []
	result_arr.resize(lth)
	for i in range(0, lth):
		for j in range(max(0, i - b_num + 1), min(a_num, i + 1)):
			result_arr[i] += a[j] * b[i - j]
	return result_arr

# generate a random integer array of given length (values 0..9)
func generate_array(sz:int) -> PackedInt32Array:
	var arr:PackedInt32Array = []
	arr.resize(sz)
	for i in range(sz):
		arr[i] = randi() % 10
	return arr
