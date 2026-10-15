extends GutTest

var canvas_scene: PackedScene = load("res://system/canvas/canvas.tscn")
var canvas: Canvas
var project: Project


func before_each():
	canvas = canvas_scene.instantiate()
	add_child(canvas)
	project = Project.new()
	project.new_project(32, 32)
	canvas.attach_project(project)


func after_each():
	canvas.free()


func test_undo_restores_previous_pixel():
	var layer_index := project.current_layer
	var page := project.get_current_page()
	canvas.save_undo_state()
	var layer := page.layers[layer_index]
	layer.set_pixel(2, 2, Color.RED)
	page.set_layer(layer_index, layer)

	canvas.undo()

	var pixel := project.get_current_page().layers[layer_index].get_pixel(2, 2)
	assert_eq(pixel.a, 0.0, "Undo should restore the empty layer")


func test_history_keeps_only_twenty_states():
	var layer_index := project.current_layer
	var page := project.get_current_page()
	for i in 21:
		canvas.save_undo_state()
		page.layers[layer_index].set_pixel(0, 0, Color(float(i) / 21.0, 0, 0, 1))

	for i in 20:
		canvas.undo()

	var pixel := project.get_current_page().layers[layer_index].get_pixel(0, 0)
	assert_gt(pixel.a, 0.5, "The oldest snapshot should have been dropped")
	canvas.undo()
	pixel = project.get_current_page().layers[layer_index].get_pixel(0, 0)
	assert_gt(pixel.a, 0.5, "A 21st undo should do nothing")


func test_undo_returns_to_the_edited_frame():
	project.next_page(false)
	var layer_index := project.current_layer
	var page := project.get_current_page()
	canvas.save_undo_state()
	var layer := page.layers[layer_index]
	layer.set_pixel(1, 1, Color.BLUE)
	page.set_layer(layer_index, layer)
	project.get_page_by_index(0)

	canvas.undo()

	assert_eq(project.current_frame, 1, "Undo should show the frame that changed")
	var pixel := project.get_current_page().layers[layer_index].get_pixel(1, 1)
	assert_eq(pixel.a, 0.0, "That frame should be back to its earlier pixels")


func test_paint_bucket_can_be_undone():
	var bucket := PaintBucket.new()
	bucket.tolerance = 0.0
	EditorState.color = Color.RED
	bucket.on_pointer_down(Vector2(4, 4), canvas)

	var layer_index := project.current_layer
	var filled := project.get_current_page().layers[layer_index].get_pixel(4, 4)
	assert_eq(filled, Color.RED, "Bucket should fill the clicked pixel")

	canvas.undo()

	var restored := project.get_current_page().layers[layer_index].get_pixel(4, 4)
	assert_eq(restored.a, 0.0, "Undo should remove the fill")


func test_dragger_undo_puts_the_layer_back():
	var layer_index := project.current_layer
	var page := project.get_current_page()
	var layer := page.layers[layer_index]
	layer.set_pixel(3, 3, Color.RED)
	page.set_layer(layer_index, layer)

	var dragger := Dragger.new()
	dragger.on_pointer_down(Vector2(3, 3), canvas)
	var cleared := project.get_current_page().layers[layer_index].get_pixel(3, 3)
	assert_eq(cleared.a, 0.0, "Drag should lift the pixels off the layer")

	canvas.undo()

	var restored := project.get_current_page().layers[layer_index].get_pixel(3, 3)
	assert_eq(restored, Color.RED, "Undo should put the lifted pixels back")
