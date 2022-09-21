extends VBoxContainer

export var freq_table_height := 8 setget _set_freq_table_height
export var line_point_count := 50
export var repeats := 50

var rng1 := FairNG.new(freq_table_height)
var rng2 := rng1.rng
var distribution := []
var use_fairng := false


func _ready():
	_set_freq_table_height(freq_table_height)
	rng1 = FairNG.new(freq_table_height, rng1.rng)


func _set_freq_table_height(v):
	freq_table_height = v
	distribution.resize(v)


func _on_Button_pressed():
	for i in freq_table_height:
		distribution[i] = 0
	
	# The CheckBox controls which random algorithm is used.
	var rng = rng1 if use_fairng else rng2
	rng1.reset_state()

	# Define number of samples per point - graphs have a fixed precision and can't show them all.
	var samples_per_point := max(repeats / line_point_count, 1)
	var last_point_value := 0.0
	$"../LinePanel/Line2D".points = PoolVector2Array([])

	# Generate Values Graph.
	for i in repeats:
		var value = rng.randf()
		last_point_value += value / samples_per_point
		distribution[floor(value * freq_table_height)] += 1
		if i % samples_per_point == 0:
			$"../LinePanel/Line2D".add_point(
				Vector2(i / float(repeats), 0.999 - last_point_value) * $"../LinePanel".rect_size
			)
			last_point_value = 0.0

	# Show Value Counts.
	$"Label2".text = ""
	for i in freq_table_height:
		$"Label2".text += str(i) + ": x" + str(distribution[i]) + "\n"
	
	# Generate Value Distribution Graph. If lines have no points, generate these.
	if $"Label2/LinePanel/Line2D2".get_point_count() != freq_table_height:
		$"Label2/LinePanel/Line2D".points = PoolVector2Array([])
		$"Label2/LinePanel/Line2D2".points = PoolVector2Array([])
		for i in freq_table_height:
			$"Label2/LinePanel/Line2D2".add_point(
				Vector2(i / float(freq_table_height), 0.8) * $"Label2/LinePanel".rect_size
			)
			$"Label2/LinePanel/Line2D".add_point(
				Vector2(i / float(freq_table_height), 0.8) * $"Label2/LinePanel".rect_size
			)
	
	var max_value := float(distribution.max())
	distribution.sort()
	for i in freq_table_height:
		# The main line shows distribution of values. The higher, the closer to the max.
		$"Label2/LinePanel/Line2D".set_point_position(
			i,
			Vector2(i / float(freq_table_height), 0.999 - distribution[i] / max_value) * $"Label2/LinePanel".rect_size
		)
		# The semi-transparent lazy line balances itself to roughly follow the solid line over a few RNG runs. 
		$"Label2/LinePanel/Line2D2".set_point_position(
			i,
			lerp(
				$"Label2/LinePanel/Line2D2".get_point_position(i),
				$"Label2/LinePanel/Line2D".get_point_position(i),
				0.15
			)
		)


func _on_Repeats_value_changed(value : float):
	repeats = value


func _on_Prec_value_changed(value : float):
	rng1 = FairNG.new(value, rng1.rng)


func _on_CheckBox_toggled(button_pressed : bool):
	use_fairng = button_pressed
