shader_type canvas_item;

uniform float radius = 0.3;
uniform vec2 P = vec2(.75, .15);

// multiply a full translation matrix by a vec2 representing a point
vec2 mult_p(mat3 m, vec2 p) {
	return (m * vec3(p,1.)).xy;
}
vec2 mult_v(mat3 m, vec2 v) {
	return (m * vec3(v,0.)).xy;
}

float Circle(vec2 p, vec2 c, float r) {
	float d = length(p-c);
	float sd = d - r;
	return smoothstep(fwidth(d), -fwidth(d), sd);
}

float transformedCircle(vec2 p, mat3 m, vec2 c, float r) {
	mat3 inv = inverse(m);
	return Circle(mult_p(inv, p), c, r);
}

float Line(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p-a, ba = b-a;
	float t = clamp(dot(pa, ba)/dot(ba, ba), 0.,1.);
	vec2 c = a+ba*t;
	float d = length(c-p);
	return smoothstep(fwidth(d), 0., d-0.001);
}

vec2 surface_p(vec2 p, vec2 c, float r) {
	vec2 n = normalize(p-c);
	return c + n*r;
}



void fragment() {
	float w = fwidth(UV.x);
	vec3 col = vec3(0);
	vec2 C = vec2(.5,.5);
	vec2 xy = UV - C;
	vec2 body_loc = vec2(0.1, 0.1);
	mat3 body_mat = mat3(vec3(1.0,-0.3, 0.), vec3(0.0,0.2, 0.), vec3(body_loc, 1.0));
	mat3 half_mat = (mat3(1.0) + body_mat)*0.5;
	mat3 inv = inverse(body_mat);
	float body = transformedCircle(xy, body_mat, vec2(0.), radius);
	float half_body = transformedCircle(xy, half_mat, vec2(0.), radius);
	float local_body = Circle(xy, vec2(0.), radius);
	float point = Circle(xy, P, .028);
	vec2 LP = mult_p(inv, P);
	float local_point = Circle(xy, LP, .028);
	float local_ovoid = transformedCircle(xy, inv, P, .028);
	vec2 l_surf = surface_p(LP, vec2(0.), radius);
	float local_line = Line(xy, LP, l_surf);
	vec2 l_abnorm = LP-l_surf;
	vec2 bad_abnorm = mult_v(body_mat, l_abnorm);
	vec2 abnorm = mult_v(inv, l_abnorm);
	float bad_line = Line(xy, P, P-bad_abnorm);
	float ler_line = Line(xy, P, P-l_abnorm);
	float line = Line(xy, P, P-abnorm);
	float newline = Line(xy, l_surf, l_surf+bad_abnorm);
	float newpoint = Circle(xy, l_surf+bad_abnorm, .028);
	//vec2 bad_surf = surface_p(mult_p(body_mat, LP), , radius);
	//float bad_abnorm = Line(xy, P, bad_surf);
	col += body * vec3(0.,0.3,1.);
	col += half_body * vec3(0.2, 0.1, 0.1);
	col += local_body * vec3(0.,.3,0.);
	col += point * vec3(0.2,0.7,1.);
	col += local_point * vec3(0.,0.7,.0);
	col += local_ovoid * vec3(0.,0.2,.0);
	col += local_line * vec3(0.,0.7,.0);
	col += bad_line * vec3(1.0,0.,.0);
	col += ler_line * vec3(0.2,0.2,.2);
	col += line * vec3(.5);
	col += newline * vec3(.5);
	col += newpoint * vec3(.5);
	//col += bad_abnorm * vec3(0.2,0.7,1.);
	//col += abnorm * vec3(0.5, 1.0, 0.6);
	COLOR = vec4(col,1.0);
}



//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
