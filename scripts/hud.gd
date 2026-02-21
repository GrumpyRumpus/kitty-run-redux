extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel
@onready var combo_label: Label = $ComboLabel


func update_score(value: int) -> void:
	score_label.text = "score: %d" % value


func update_health(health: int) -> void:
	health_label.text = "\u2661 ".repeat(maxi(0, 3 - health)) + "\u2764".repeat(health)


func update_combo(count: int) -> void:
	if count >= 2:
		combo_label.text = "x%d" % count
		combo_label.visible = true
	else:
		combo_label.visible = false
