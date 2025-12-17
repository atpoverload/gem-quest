shader_type canvas_item;

void vertex() {
	VERTEX.y += 1.075 * VERTEX.x - 375.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
