shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (COLOR.a == 0.0) { discard; }
	vec3 c = COLOR.rgb;
	c += 3.0*vec3(0.3, 0.0, 0.7);
	c /= 4.0;
	ALBEDO.rgb = c;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
