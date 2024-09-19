shader_type spatial;

uniform float damaged = 0.0;



vec3 redden(vec3 c) {
	float mult = 2.0*damaged;
	return (c.xyz + mult*vec3(1.0, 0.0, 0.0))/(mult + 1.0);
}

void fragment() {
	if (damaged > 0.0 && COLOR.w > 0.0) {
		ALBEDO.rgb = redden(COLOR.rgb);
		EMISSION = redden(COLOR.rgb)*0.1;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
