extends RefCounted
class_name ClubData
## Arcade club profiles used by aiming, shot calculation, and the HUD.

const CLUBS := [
	{
		"name": "Driver",
		"short_name": "DR",
		"category": "wood",
		"min_speed": 16.0,
		"max_speed": 46.0,
		"min_angle": 13.0,
		"max_angle": 29.0,
		"backspin": 2200.0,
		"backspin_power": 1800.0,
		"roll_resistance": 0.90,
		"bounce": 0.20,
	},
	{
		"name": "3-Wood",
		"short_name": "3W",
		"category": "wood",
		"min_speed": 14.0,
		"max_speed": 40.0,
		"min_angle": 15.0,
		"max_angle": 27.0,
		"backspin": 2500.0,
		"backspin_power": 1600.0,
		"roll_resistance": 1.00,
		"bounce": 0.19,
	},
	{
		"name": "5-Iron",
		"short_name": "5I",
		"category": "iron",
		"min_speed": 12.0,
		"max_speed": 33.0,
		"min_angle": 22.0,
		"max_angle": 38.0,
		"backspin": 3300.0,
		"backspin_power": 1700.0,
		"roll_resistance": 1.18,
		"bounce": 0.16,
	},
	{
		"name": "7-Iron",
		"short_name": "7I",
		"category": "iron",
		"min_speed": 10.0,
		"max_speed": 28.0,
		"min_angle": 27.0,
		"max_angle": 44.0,
		"backspin": 3900.0,
		"backspin_power": 1600.0,
		"roll_resistance": 1.28,
		"bounce": 0.14,
	},
	{
		"name": "Wedge",
		"short_name": "W",
		"category": "wedge",
		"min_speed": 8.0,
		"max_speed": 22.0,
		"min_angle": 38.0,
		"max_angle": 58.0,
		"backspin": 5000.0,
		"backspin_power": 1800.0,
		"roll_resistance": 1.65,
		"bounce": 0.10,
	},
	{
		"name": "Putter",
		"short_name": "PT",
		"category": "putter",
		"min_speed": 2.0,
		"max_speed": 9.0,
		"min_angle": 2.0,
		"max_angle": 5.0,
		"backspin": 0.0,
		"backspin_power": 0.0,
		"roll_resistance": 0.72,
		"bounce": 0.0,
	},
]


static func get_club(index: int) -> Dictionary:
	return CLUBS[posmod(index, CLUBS.size())]


static func count() -> int:
	return CLUBS.size()
