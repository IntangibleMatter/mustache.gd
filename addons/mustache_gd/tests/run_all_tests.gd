extends VBoxContainer

@onready var test_runner_container: HBoxContainer = $ScrollContainer/TestRunnerContainer
@onready var total_passed: Label = $TotalPassed

var total_test_count: int
var passed_tests: int

func _ready() -> void:
	await get_tree().process_frame
	for child in test_runner_container.get_children():
		child.finished_tests.connect(update_total_passed)
		(func() -> void:
			await get_tree().process_frame
			child.call_deferred("run_tests")).call_deferred()
		await get_tree().process_frame
		#child.call_deferred("run_tests")


func update_total_passed(tests: int, passed: int) -> void:
	total_test_count += tests
	passed_tests += passed
	
	total_passed.text = "Passed: {0}/{1}".format([passed_tests, total_test_count])
