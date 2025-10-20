shader_type canvas_item;

void vertex() {
	//vec2 vert = VERTEX - vec2(600, 450);
	float v_x = VERTEX.x - 600.0;
	float v_y = VERTEX.y - 450.0;
	VERTEX.x += 2000.0 * PI * sin(v_x) * sign(v_y);
	//VERTEX.y += 450.0 * sign(vert.y) * sin(vert.x);
}
