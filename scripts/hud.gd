extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var health_label: Label = $HealthLabel


func update_score(value: int) -> void:
	score_label.text = "score: %d" % value


func update_health(health: int) -> void:
	health_label.text = "\u2661 ".repeat(maxi(0, 3 - health)) + "\u2764".repeat(health)
