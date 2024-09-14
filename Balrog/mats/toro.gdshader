shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;

const float MAX_DIST = 100.0;
const int MAX_STEPS = 100;
const float SURF_DIST = 1e-3; //0.001

varying vec3 camera; // Local Camera position
varying vec3 position; //Vertex Position

const float radius = 1.0;
uniform float thickness = 0.5;


float SdfTorus(vec3 p) { // return distance and normal
	vec3 vert = vec3(0.0, p.y, 0.0);
	vec3 lat = p - vert;
	vec3 lat_c = normalize(lat) * radius;
	vec3 abnormal = p - lat_c;
	float dist = length(abnormal) - thickness;
	//vec3 norm = normalize(abnormal);
	return dist;
}

vec3 NormalTorus(vec3 p) {
	vec3 vert = vec3(0.0, p.y, 0.0);
	vec3 lat = p - vert;
	vec3 lat_c = normalize(lat) * radius;
	vec3 abnormal = p - lat_c;
	//vec3 norm = normalize(abnormal);
	return normalize(abnormal);
}

// return total distance travelled ( plus extra)
vec2 RayMarch(vec3 ro, vec3 rd) { //vec2(total_dist, nearest_dist)
	float dO = 0.0; // Distance ray has already travelled
	float minDist = MAX_DIST;

	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 p = ro + dO * rd;
		float dist = SdfTorus(p);
		if (dist < minDist) {
			minDist = dist;
		}
		dO += dist;
		if (dist < SURF_DIST || dO > MAX_DIST) {
			break;
		}
	}
	return vec2(dO, minDist);
}


void vertex() {
	position = VERTEX;
	camera = (inverse(MODELVIEW_MATRIX) * vec4(0,0,0,1)).xyz; // Camera Position in Local

}

void fragment() {
	vec3 ro = camera;
	vec3 rd = normalize(position - ro);
	//
	vec3 n;
	vec3 col;

	vec2 rm = RayMarch(ro, rd);
	float d = rm.x;
	float dd = rm.y;
	vec3 p = ro + rd * d;
	if (d >= MAX_DIST) {
		if (dd > 1.0) {
			discard;
		}
		col = vec3(0.0, 0.0, 0.0);
		ALPHA = 0.5*(1.0-dd);
	} else {
		n = NormalTorus(p);
		//n = normalize(p);
		col = vec3(0.2+0.15*n.x, 0.9-0.2*n.z, 0.1+0.3*n.y);
	}
	// Transform to clip space
    //vec4 view_space_position = VIEW_MATRIX * vec4(p, 1.0);
    //vec4 clip_space_position = PROJECTION_MATRIX * view_space_position;
    //// Compute depth
    //float ndc_depth = clip_space_position.z / clip_space_position.w;
    //DEPTH = ndc_depth * 0.5 + 0.5; // Map from [-1, 1] to [0, 1]
	ALBEDO = col;
}


//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
