extends RefCounted

static func box(size: Vector3, radius: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var bevel := minf(radius, minf(half.x, minf(half.y, half.z)) * 0.8)
	var inner := half - Vector3.ONE * bevel
	var faces := [
		[Vector3(0, 0, half.z), Vector3.RIGHT, Vector3.UP, Vector2(size.x, size.y)],
		[Vector3(0, 0, -half.z), Vector3.LEFT, Vector3.UP, Vector2(size.x, size.y)],
		[Vector3(half.x, 0, 0), Vector3.FORWARD, Vector3.UP, Vector2(size.z, size.y)],
		[Vector3(-half.x, 0, 0), Vector3.BACK, Vector3.UP, Vector2(size.z, size.y)],
		[Vector3(0, half.y, 0), Vector3.RIGHT, Vector3.FORWARD, Vector2(size.x, size.z)],
		[Vector3(0, -half.y, 0), Vector3.RIGHT, Vector3.BACK, Vector2(size.x, size.z)]
	]
	var steps := 8
	for face in faces:
		for y in range(steps):
			for x in range(steps):
				for corner in [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(1, 0)]:
					var uv: Vector2 = (Vector2(x, y) + corner) / float(steps)
					var point: Vector3 = face[0] + face[1] * (uv.x - 0.5) * face[3].x + face[2] * (uv.y - 0.5) * face[3].y
					var anchor := Vector3(clampf(point.x, -inner.x, inner.x), clampf(point.y, -inner.y, inner.y), clampf(point.z, -inner.z, inner.z))
					var normal := (point - anchor).normalized()
					tool.set_normal(normal)
					tool.set_uv(uv)
					tool.add_vertex(anchor + normal * bevel)
	return tool.commit()
