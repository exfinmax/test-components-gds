extends PackDemo

func _ready():
	pack_name = "Builder"
	._ready()

func _populate_demo():
	# instantiate grid placement and show placing a marker on click
	var grid = GridPlacementComponent.new()
	grid.cell_size = 32
	add_child(grid)
	var marker = Sprite2D.new()
	marker.texture = GradientTexture2D.new()
	grid.cell_placed.connect(Callable(self, "_on_cell_placed"))
	print("Builder demo: click to place cells, check _on_cell_placed")

func _on_cell_placed(coords):
	print("placed at", coords)
