class_name VoxelUtil
extends RefCounted

const CS := 16
const WORLD_H := 256
const SEA_LEVEL := 48

static func idx(x: int, y: int, z: int) -> int:
	return (y * CS + z) * CS + x

static func in_chunk(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < CS and z >= 0 and z < CS and y >= 0 and y < WORLD_H

static func chunk_key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]

static func hash2(x: int, z: int, seed: int) -> float:
	var v := sin(float(x) * 12.9898 + float(z) * 78.233 + float(seed) * 0.0173) * 43758.5453
	return v - floor(v)

static func hash3(x: int, y: int, z: int, seed: int) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 43.712 + float(z) * 78.233 + float(seed) * 0.0173) * 43758.5453
	return v - floor(v)

static func div(v: int) -> int:
	return int(floor(float(v) / float(CS)))

static func world_to_chunk(v: int) -> int:
	return div(v)

static func local(v: int) -> int:
	return v - div(v) * CS

static func chunk_origin(cx: int, cz: int) -> Vector3i:
	return Vector3i(cx * CS, 0, cz * CS)
