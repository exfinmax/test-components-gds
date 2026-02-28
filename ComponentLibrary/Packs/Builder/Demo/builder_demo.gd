extends "res://ComponentLibrary/Shared/pack_demo.gd"

@export var pack_name:String = "Builder"

func _populate_demo():
    # instantiate grid placement and show placing a marker on click
    var grid = GridPlacementComponent.new()
    grid.cell_size = 32
    add_child(grid)
    var marker = Sprite2D.new()
    marker.texture = GradientTexture.new()
    grid.connect("cell_placed", self, "_on_cell_placed")
    print("Builder demo: click to place cells, check _on_cell_placed");

func _on_cell_placed(coords):
    print("placed at", coords)
