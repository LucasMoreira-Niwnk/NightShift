extends RefCounted

const REVISION := 2
const HEIGHT := 4.2

# Canonical room coordinates are kept for narrative data; the constructed floor
# now occupies x[-8,8], z[-14,10], directly over the ground-floor footprint.
static func upper_point(point: Vector3) -> Vector3:
	return Vector3(point.x * 0.8, point.y, -point.z - 40.0)

static func upper_legacy(point: Vector3) -> Vector3:
	return Vector3(point.x / 0.8, point.y, -point.z - 40.0)

static func migrate(point: Vector3) -> Vector3:
	if point.y > 3.5 and point.z < -25 and point.x >= -10:
		return upper_point(point)
	if point.x < -10:
		return Vector3(-9.7, 4.25, -9) if point.y > 2 else Vector3(-9.7, 0.05, 1)
	if point.z < -16 and point.y > 0.3:
		return Vector3(0, 4.25, -12.5) if point.y > 3 else Vector3(0, 2.15, -23.2)
	return point
