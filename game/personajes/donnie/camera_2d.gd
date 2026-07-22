extends Camera2D

func _ready():
	enabled = true
	# límites del escenario (ejemplo: un nivel de 1024x768)
	limit_left = 0
	limit_top = 0
	limit_right = 570
	limit_bottom = 312
	
	# suavizado de movimiento
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
