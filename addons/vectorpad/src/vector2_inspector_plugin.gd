@tool
class_name Vector2InspectorPlugin
extends EditorInspectorPlugin

func _can_handle(object):
	return true


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if type == TYPE_VECTOR2:
		var editor_property = Vector2EditorProperty.new()
		editor_property.setup(object, name)
		add_property_editor(name, editor_property)
		return true
	return false


class Vector2EditorProperty:
	extends EditorProperty

	const DEFAULT_VECTOR_DRAWER_MINIMUM_SIZE := Vector2(120, 120)
	const DEFAULT_SPIN_STEP := 0.01
	const TAG_MINIMUM_WIDTH := 20.0
	const TAG_COLOR := Color(0.18, 0.18, 0.2)

	var target_object: Object
	var target_property: String
	var updating := false

	var spin_box_x: SpinBox
	var spin_box_y: SpinBox
	var vector_drawer: Vector2Drawer

	func setup(object: Object, property_name: String):
		target_object = object
		target_property = property_name
		set_object_and_property(object, property_name)
		set_process(true)

		var root_container := HBoxContainer.new()
		root_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(root_container)

		var fields_container := VBoxContainer.new()
		fields_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root_container.add_child(fields_container)

		var row_one := _make_row("x")
		fields_container.add_child(row_one[0])
		spin_box_x = row_one[1]
		var row_two := _make_row("y")
		fields_container.add_child(row_two[0])
		spin_box_y = row_two[1]

		vector_drawer = Vector2Drawer.new()
		vector_drawer.custom_minimum_size = DEFAULT_VECTOR_DRAWER_MINIMUM_SIZE
		root_container.add_child(vector_drawer)

		spin_box_x.value_changed.connect(_on_spin_changed)
		spin_box_y.value_changed.connect(_on_spin_changed)
		vector_drawer.property_changed.connect(_on_pad_changed)

		var current_vector := Vector2.ZERO
		if object and object.has_method("get"):
			current_vector = object.get(property_name)
		updating = true
		spin_box_x.value = current_vector.x
		spin_box_y.value = current_vector.y
		vector_drawer.value = current_vector
		updating = false

	func update_property():
		if updating:
			return
		if target_object == null:
			return
		var current_vector := Vector2.ZERO
		if target_object.has_method("get"):
			current_vector = target_object.get(target_property)
		updating = true
		spin_box_x.value = current_vector.x
		spin_box_y.value = current_vector.y
		vector_drawer.value = current_vector
		updating = false

	func _process(_delta: float) -> void:
		if updating:
			return
		if target_object == null:
			return
		if not target_object.has_method("get"):
			return
		var v = target_object.get(target_property)
		if typeof(v) == TYPE_VECTOR2 and v != vector_drawer.value:
			updating = true
			spin_box_x.value = v.x
			spin_box_y.value = v.y
			vector_drawer.value = v
			updating = false

	func _make_row(tag_text: String) -> Array:
		var row_container := HBoxContainer.new()
		var tag_color_rect := ColorRect.new()
		tag_color_rect.custom_minimum_size = Vector2(TAG_MINIMUM_WIDTH, 0)
		tag_color_rect.color = TAG_COLOR
		row_container.add_child(tag_color_rect)
		var label := Label.new()
		label.text = tag_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag_color_rect.add_child(label)
		label.anchor_right = 1
		label.anchor_bottom = 1
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var spin_box := SpinBox.new()
		spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin_box.step = DEFAULT_SPIN_STEP
		spin_box.allow_greater = true
		spin_box.allow_lesser = true
		row_container.add_child(spin_box)
		return [row_container, spin_box]

	func _on_spin_changed(new_value: float):
		if updating:
			return
		var new_vector := Vector2(spin_box_x.value, spin_box_y.value)
		updating = true
		vector_drawer.value = new_vector
		updating = false
		emit_changed(target_property, new_vector)

	func _on_pad_changed(new_value: Vector2):
		if updating:
			return
		updating = true
		spin_box_x.value = new_value.x
		spin_box_y.value = new_value.y
		updating = false
		emit_changed(target_property, new_value)


class Vector2Drawer:
	extends Control
	signal property_changed(new_value: Vector2)

	const BACKGROUND_COLOR := Color(1, 1, 1, 1)

	var value: Vector2 = Vector2(50, 0):
		set(requested_value):
			value = requested_value
			_update_shader_parameters()
			queue_redraw()
	var shader_material: ShaderMaterial
	var is_dragging := false

	func _gui_input(event):
		if event is InputEventMouseButton:
			var mouse_button_event := event as InputEventMouseButton
			if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
				is_dragging = true
				var canvas_center = size / 2
				value = mouse_button_event.position - canvas_center
				property_changed.emit(value)
				return
			elif mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
				is_dragging = false
				return
		elif event is InputEventMouseMotion and is_dragging:
			var mouse_motion_event := event as InputEventMouseMotion
			var canvas_center = size / 2
			value = mouse_motion_event.position - canvas_center
			property_changed.emit(value)
			return

	func _ready():
		var shader: Shader = load("res://addons/vectorpad/src/vector_pad_shader.gdshader")
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		material = shader_material
		_update_shader_parameters()

	func _notification(notification):
		if notification == NOTIFICATION_RESIZED:
			_update_shader_parameters()

	func _update_shader_parameters():
		if shader_material == null:
			return
		shader_material.set_shader_parameter("canvas_size", size)
		shader_material.set_shader_parameter("vector_pixels", value)

	func _draw():
		draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR, true)
