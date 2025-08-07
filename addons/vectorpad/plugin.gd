@tool
extends EditorPlugin

var vector_pad_inspector: EditorInspectorPlugin

func _enter_tree() -> void:
    vector_pad_inspector = load("res://addons/vectorpad/src/vector2_inspector_plugin.gd").new()
    add_inspector_plugin(vector_pad_inspector)

func _exit_tree() -> void:
    if vector_pad_inspector:
        remove_inspector_plugin(vector_pad_inspector)
        vector_pad_inspector = null
