tool
extends EditorPlugin

func _enter_tree():
    # ensure dependencies are loaded so scripts extending ComponentBase work
    preload("res://ComponentLibrary/Dependencies/component_base.gd")
    preload("res://ComponentLibrary/Dependencies/character_component_base.gd")
    print("ComponentLibrary plugin loaded")

    add_tool_menu_item("ComponentLibrary/Open Pack Demo", self, "_on_open_demo")

func _exit_tree():
    remove_tool_menu_item("ComponentLibrary/Open Pack Demo")
    print("ComponentLibrary plugin unloaded")

func _on_open_demo():
    var packs = ["Action","Builder","Card","Foundation","Platformer","Puzzle","Racing","Roguelike","RPG","Shooter","Strategy","Survival","Time","UI","VFX"]
    var choice = EditorInterface.get_editor_interface().get_file_system().get_dialog().get_open_file_name() # dummy
    # in a real plugin we would show a popup listing demos
    print("Use open file dialog to pick a demo scene")
