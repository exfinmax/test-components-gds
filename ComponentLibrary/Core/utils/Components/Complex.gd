class_name Complex
extends RefCounted

# components are stored as floats to support FFT calculations
var real:float
var imag:float

func _init(_real:float, _imag:float = 0.0) -> void:
	real = _real
	imag = _imag

func add(another_complex: Complex) -> Complex:
	return Complex.new(real + another_complex.real, imag + another_complex.imag)

func subtract(another_complex: Complex) -> Complex:
	return Complex.new(real - another_complex.real, imag - another_complex.imag)

# note: correct spelling and semantics for complex multiplication
func multiply(another_complex: Complex) -> Complex:
	return Complex.new(
		real * another_complex.real - imag * another_complex.imag,
		real * another_complex.imag + imag * another_complex.real
	)

func conjugate() -> Complex:
	return Complex.new(self.real,self.imag * -1)

func _to_string() -> String:
	return "实数%f，虚数%f" % [real,imag]
