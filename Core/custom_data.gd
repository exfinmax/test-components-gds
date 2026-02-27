class_name CustomData

class DataBase:
	pass

class Data1 extends DataBase:
	var i:int
	
	func _init(_i:int) -> void:
		i = _i
	

var data:DataBase

func _init(_data:DataBase) -> void:
	data = _data
