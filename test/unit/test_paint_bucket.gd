extends GutTest

const WIDTH := 8
const HEIGHT := 8

var bucket: PaintBucket
var project: Project
var canvas: Canvas


func before_each():
	bucket = PaintBucket.new()
	bucket.tolerance = 0.0
	project = Project.new()
	project.new_project(WIDTH, HEIGHT)
	canvas = Canvas.new()
	canvas._project = project
	EditorState.color = Color.RED


func after_each():
	canvas.free()


func test_full_screen_fill_terminates():
	bucket.on_pointer_down(Vector2(3, 3), canvas)
	var layer = _layer()
	var filled := 0
	for y in HEIGHT:
		for x in WIDTH:
			assert_eq(layer.get_pixel(x, y), Color.RED, "Pixel %d,%d filled" % [x, y])
			filled += 1
	assert_eq(filled, WIDTH * HEIGHT, "Fill stops after every pixel in the small canvas")


func test_contained_region_respects_border():
	var layer = _layer()
	for x in range(2, 6):
		layer.set_pixel(x, 2, Color.BLUE)
		layer.set_pixel(x, 5, Color.BLUE)
	for y in range(3, 5):
		layer.set_pixel(2, y, Color.BLUE)
		layer.set_pixel(5, y, Color.BLUE)

	bucket.on_pointer_down(Vector2(3, 3), canvas)
	layer = _layer()

	assert_eq(layer.get_pixel(3, 3), Color.RED, "Inside the border is filled")
	assert_eq(layer.get_pixel(4, 4), Color.RED, "The rest of the inside is filled")
	assert_eq(layer.get_pixel(2, 2), Color.BLUE, "The border stays in place")
	assert_eq(layer.get_pixel(0, 0), Color.TRANSPARENT, "Outside the border stays empty")


func test_tolerance_keeps_distant_colors():
	bucket.tolerance = 0.1
	var layer = _layer()
	layer.set_pixel(1, 0, Color(1, 1, 1, 0.1))
	layer.set_pixel(2, 0, Color.BLACK)

	bucket.on_pointer_down(Vector2(0, 0), canvas)
	layer = _layer()

	assert_eq(layer.get_pixel(1, 0), Color.RED, "A nearby color within tolerance is filled")
	assert_eq(layer.get_pixel(2, 0), Color.BLACK, "A color past tolerance is left alone")


func test_edge_fill_does_not_error():
	bucket.on_pointer_down(Vector2(0, 0), canvas)
	var layer = _layer()
	assert_eq(layer.get_pixel(0, 0), Color.RED, "Top left edge filled")
	assert_eq(layer.get_pixel(WIDTH - 1, 0), Color.RED, "Top right edge filled")
	assert_eq(layer.get_pixel(0, HEIGHT - 1), Color.RED, "Bottom left edge filled")
	assert_eq(layer.get_pixel(WIDTH - 1, HEIGHT - 1), Color.RED, "Bottom right edge filled")


func test_page_layer_is_updated():
	var before = _layer().get_pixel(4, 4)
	bucket.on_pointer_down(Vector2(4, 4), canvas)
	var page = project.get_current_page()
	var after = page.layers[project.current_layer].get_pixel(4, 4)
	assert_ne(before, after, "The stored layer changed")
	assert_eq(after, Color.RED, "The page holds the fill color")
	var stored = project.frames[project.current_frame].layers[project.current_layer]
	assert_eq(stored.get_pixel(1, 1), Color.RED, "The frame stores the filled layer")


func _layer() -> Image:
	return project.get_current_page().layers[project.current_layer]
