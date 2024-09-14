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

float noiseSdf(vec3 p) {
	float freq = 4.0;
	return 30.0*sin(p.x*freq*2.2) + sin(p.x*freq*9.2) + sin(p.y*freq*8.2) +
		30.0*sin(p.y*freq*1.5) + 30.0*sin(p.z*freq*1.7) + sin(p.z*freq*7.2);
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.71, 0.11, 0.93));
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}


float fractalNoise(vec3 p) {
    const int octaves = 2;
    float persistence = 0.4;
    float frequency = 1.0;
    float amplitude = 1.0;
    float total = 0.0;

    for (int i = 0; i < octaves; i++) {
        total += noiseSdf(p * frequency) * amplitude;
        frequency *= 2.5;
        amplitude *= persistence;
    }
    return total;
}

float sdf(vec3 p) { // return distance and normal
	vec3 vert = vec3(0.0, p.y, 0.0);
	vec3 lat = p - vert;
	vec3 lat_c = normalize(lat) * radius;
	vec3 abnormal = p - lat_c;
	float dist = length(abnormal) - thickness + fractalNoise(p)*0.001;
	//vec3 norm = normalize(abnormal);
	return dist;
}

vec3 estimateNormal(vec3 p) {
    float epsilon = 0.0001; // Small offset for finite differences
    vec2 e = vec2(1.0, -1.0) * epsilon;

    // Compute finite differences in each direction
    float dx = sdf(p + vec3(e.x, 0.0, 0.0)) - sdf(p + vec3(e.y, 0.0, 0.0));
    float dy = sdf(p + vec3(0.0, e.x, 0.0)) - sdf(p + vec3(0.0, e.y, 0.0));
    float dz = sdf(p + vec3(0.0, 0.0, e.x)) - sdf(p + vec3(0.0, 0.0, e.y));

    // Combine the partial derivatives into the gradient vector
    vec3 normal = vec3(dx, dy, dz);

    // Normalize the gradient to get the unit normal vector
    return normalize(normal);
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
		float dist = sdf(p);
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
		ALPHA = 0.9*(1.0-pow(dd, 0.25));
	} else {
		n = estimateNormal(p);
		//n = normalize(p);
		//float r = abs(1.0 - 2.0*mod(n.x*2.0, 1.0));
		//float g = abs(1.0 - 2.0*mod(n.y*2.0, 1.0));
		//float b = abs(1.0 - 2.0*mod(n.z*2.0, 1.0));
		float r = (n.x+0.5)/1.7;
		float g = (n.y+0.5)/1.7;
		float b = (n.z+0.5)/1.7;
		col = vec3(r, g, b);
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
