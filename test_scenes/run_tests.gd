extends ScrollContainer

signal finished_tests(total: int, passed: int)

@export_file_path("*.json") var file_path: String

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var passed_label: Label = %PassedLabel

var tests: Array[Dictionary]

var failed: int = 0

var lambda_multiple_calls := 0

## Used for testing the lambdas in the lambda module since Godot can't create
## lambdas from arbitrary strings at present.
var lambda_tests: Dictionary[String, Callable] = {
	"Interpolation": func(): return "world",
	"Interpolation - Expansion": func():
		return "{{planet}}",
	"Interpolation - Alternate Delimiters": func():
		return "|planet| => {{planet}}",
	"Interpolation - Multiple Calls": func():
		lambda_multiple_calls += 1
		return lambda_multiple_calls,
	"Escaping": func():
		return ">",
	"Section": func(text: String):
		return "yes" if text == "{{x}}" else "no",
	"Section - Expansion": func(text: String):
		return text + "{{planet}}" + text,
	"Section - Alternate Delimiters": func(text: String):
		return text + "{{planet}} => |planet|" + text,
	"Section - Multiple Calls": func(text: String):
		return "__" + text  + "__",
	"Inverted Section": func(): return false
}


func _ready() -> void:
	prints("\n  \n	\n".strip_edges().is_empty())
	if not file_path:
		return

	#title = file_path.get_basename()

	load_tests()
	#run_tests()


func load_tests() -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var json := JSON.new()
	var json_err := json.parse(file.get_as_text())
	prints("json loaded:", json_err)
	var json_data: Dictionary = json.data
	tests.assign(json_data.tests)
	clean_data()
	print(tests)
	passed_label.text = "{2} - PASSED: {0}/{1}".format(
		[0, 0, file_path.get_file().get_basename()]
	)


func make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func run_tests() -> void:
	for test in tests:
		run_test(test)
		#await get_tree().process_frame
		#await get_tree().process_frame
	passed_label.text = "{2} - PASSED: {0}/{1}".format(
		[tests.size() - failed, tests.size(), file_path.get_file().get_basename()]
	)
	finished_tests.emit(tests.size(), tests.size() - failed)


func run_test(test: Dictionary, foldable: FoldableContainer = null) -> void:
	if test.name in [
		#"Multiline",
		#"Empty List",
		#"Standalone Without Previous Line",
		#"Standalone Without Newline",
		#"Standalone Line Endings",
		#"Standalone Indentation",
		"Doubled",
		
		]:
		prints("OH SHIT WATCH THIS")
	
	if not foldable:
		foldable = FoldableContainer.new()

	var foldable_contents: VBoxContainer

	if foldable.get_child_count() > 0:
		if foldable.get_child(0) is VBoxContainer:
			foldable_contents = foldable.get_child(0)
			for child in foldable_contents.get_children():
				child.queue_free()
	else:
		foldable_contents = VBoxContainer.new()
		foldable.add_child(foldable_contents)

	foldable.fold()
	foldable.title = test.name
	
	foldable_contents.add_child(make_label(test.desc))

	var rerun_button := Button.new()
	rerun_button.text = "Rerun"
	rerun_button.pressed.connect(run_test.bind(test, foldable))
	foldable_contents.add_child(rerun_button)

	var succeed_label := Label.new()

	print("\n\n---\n\n")
	print(test.name)
	print(test.desc)
	prints("data", test.data)
	prints("template", test.template)
	foldable_contents.add_child(make_label("DATA: " + str(test.data)))
	foldable_contents.add_child(make_label("TEMPLATE: " + str(test.template).c_escape()))

	var mustache := Mustache.new()

	if test.data is Dictionary:
		if "lambda" in test.data:
			test.data.lambda = lambda_tests[test.name]

	mustache.add_to_context(test.data)

	if "partials" in test:
		var partial_collection := FoldableContainer.new()
		partial_collection.title = "Partials"
		partial_collection.fold()
		for partial in test.partials:
			var par := MustacheTemplate.create_from_string(test.partials[partial])
			mustache.add_partial(partial, par)
			partial_collection.add_child(make_label(partial + " = " + test.partials[partial]))
		foldable_contents.add_child(partial_collection)

	var template := MustacheTemplate.create_from_string(test.template)
	var rendered := mustache.render(template)
	if rendered == test.expected:
		#prints("RENDERED AND EXPECTED ARE THE SAME")
		succeed_label.text = "✅"
	else:
		printerr("Rendered and expected are different for test: %s" % test.name)
		failed += 1
		prints("parsed template:", template.contents)
		succeed_label.text = "❌"

	foldable_contents.add_spacer(false)
	print("rendered:\n\n")
	print(rendered)
	foldable_contents.add_child(make_label("Rendered:\n" + rendered.c_escape()))

	print("expected:\n\n")
	print(test.expected)
	foldable_contents.add_child(make_label("Expected:\n" + test.expected.c_escape()))

	foldable.add_title_bar_control(succeed_label)
	if not foldable.is_inside_tree():
		vbox.add_child(foldable)


func clean_data() -> void:
	for test in tests:
		var dat = test.data

		if dat is Dictionary:
			for val in dat:
				if dat[val] is float:
					if is_equal_approx(dat[val], floor(dat[val])):
						dat[val] = int(dat[val])
				elif dat[val] is Array:
					for i in dat[val].size():
						if dat[val][i] is float:
							if is_equal_approx(dat[val][i], floor(dat[val][i])):
								dat[val][i] = int(dat[val][i])
						elif dat[val][i] is Dictionary or dat[val][i] is Array:
							for j in (dat[val][i] if dat[val][i] is Dictionary else dat[val][i].size()):
								if dat[val][i][j] is float:
									if is_equal_approx(dat[val][i][j], floor(dat[val][i][j])):
										dat[val][i][j] = int(dat[val][i][j])
										
		elif dat is float:
			if is_equal_approx(dat, floor(dat)):
				test.data = int(dat)
		elif dat is Array:
			for i in dat.size():
				if dat[i] is float:
					if is_equal_approx(dat[i], floor(dat[i])):
						dat[i] = int(dat[i])
