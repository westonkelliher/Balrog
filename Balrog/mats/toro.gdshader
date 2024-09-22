shader_type spatial;
//render_mode unshaded;
render_mode cull_disabled;
render_mode depth_draw_always;

const float MAX_DIST = 100.0;
const int MAX_STEPS = 100;
const float SURF_DIST = 1e-3; //0.001

varying vec3 camera; // Local Camera position
varying vec3 position; //Vertex Position
varying mat4 modelview;

uniform float ring_radius = 1.0;
uniform float scale = 1.0;

float noiseSdf(vec3 p) {
	float freq = 4.0;
	//return 30.0*sin(p.x*freq*2.2) + sin(p.x*freq*9.2) + sin(p.y*freq*8.2) +
		//30.0*sin(p.y*freq*1.5) + 30.0*sin(p.z*freq*1.7) + sin(p.z*freq*7.2);
	return max(sin(p.x*freq*9.2) + sin(p.y*freq*8.2) + sin(p.z*freq*7.2),0.0);
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.71, 0.11, 0.93));
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
    float cos_angle = cos(angle);
    float sin_angle = sin(angle);
    return v * cos_angle +
           cross(axis, v) * sin_angle +
           axis * dot(axis, v) * (1.0 - cos_angle);
}


float fractalNoise(vec3 p) {
    const int octaves = 5;
    float persistence = 0.5;
    float frequency = 0.2;
    float amplitude = 2.0;
    float total = 0.0;
	vec3 pp = p;

    for (int i = 0; i < octaves; i++) {
		pp += vec3(.21);
		pp = rotate(pp, vec3(0.1, 0.3, 0.6), PI*0.4);
        total += noiseSdf(pp * frequency) * amplitude;
        frequency *= 2.0;
        amplitude *= persistence;
    }
    return total;
}

float sdfTorus(vec3 p, float radius, float thickness) { // return distance and normal
	vec3 vert = vec3(0.0, p.y, 0.0);
	vec3 lat = p - vert;
	vec3 lat_c = normalize(lat) * radius;
	vec3 abnormal = p - lat_c;
	float dist = length(abnormal) - thickness + fractalNoise(p)*0.0002;
	//vec3 norm = normalize(abnormal);
	return dist;
}

vec3 estimateNormal(vec3 p) {
    float epsilon = 0.01; // Small offset for finite differences
    vec2 e = vec2(1.0, -1.0) * epsilon;

    // Compute finite differences in each direction
    float dx = sdfTorus(p + vec3(e.x, 0.0, 0.0), ring_radius*scale, 1.0*scale) - 
		sdfTorus(p + vec3(e.y, 0.0, 0.0), ring_radius*scale, 1.0*scale);
    float dy = sdfTorus(p + vec3(0.0, e.x, 0.0), ring_radius*scale, 1.0*scale) - 
		sdfTorus(p + vec3(0.0, e.y, 0.0), ring_radius*scale, 1.0*scale);
    float dz = sdfTorus(p + vec3(0.0, 0.0, e.x), ring_radius*scale, 1.0*scale) - 
		sdfTorus(p + vec3(0.0, 0.0, e.y), ring_radius*scale, 1.0*scale);

    // Combine the partial derivatives into the gradient vector
    vec3 normal = vec3(dx, dy, dz);

    // Normalize the gradient to get the unit normal vector
    return normalize(normal);
}

vec3 NormalTorus(vec3 p) {
	vec3 vert = vec3(0.0, p.y, 0.0);
	vec3 lat = p - vert;
	vec3 lat_c = normalize(lat) * ring_radius;
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
		float dist = sdfTorus(p, ring_radius*scale, scale);
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
	modelview = MODELVIEW_MATRIX;
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
	//if (d < DEPTH) {
		//discard;
	//}
	//float angle_factor = length(rd.y);
	//float qqq = 0.5;
	//vec4 clip_pos = PROJECTION_MATRIX * modelview * vec4(p, 1.0);
	//DEPTH = (clip_pos.z / clip_pos.w) * 0.5 + 0.5;
	//DEPTH = 1.0/(2.+pow(d*900.0,0.7));
	//DEPTH = 1.0/(pow(d*70.0,1.0));
	//DEPTH = -1.5;
	if (d >= MAX_DIST) {
		discard;
		if (dd > 0.1) {
			discard;
		}
		col = vec3(0.0, 0.0, 0.0);
		NORMAL = vec3(0.0);
		//ALPHA = 0.1*(1.0-pow(dd, 0.25));
	} else {
		n = estimateNormal(p);
		NORMAL = n;
		//n = normalize(p);
		//float r = abs(1.0 - 2.0*mod(n.x*2.0, 1.0));
		//float g = abs(1.0 - 2.0*mod(n.y*2.0, 1.0));
		//float b = abs(1.0 - 2.0*mod(n.z*2.0, 1.0));
		float r = (n.x+0.5)/1.7;
		float g = (n.y+0.5)/1.7;
		float b = (n.z+0.5)/1.7;
		col = vec3(r, g, b);
		//ALPHA = 0.9;
		float blackness = smoothstep(-0.1, 0.0, dot(n, rd));
		vec3 grass_c = vec3(0.1, 0.5, 0.05);
		vec3 dirt_c = vec3(0.6, 0.8, 0.1);
		float m = clamp(fractalNoise(p)*0.2, 0.0, 1.0);
		vec3 ground_color = mix(grass_c, dirt_c, 0.2-m*0.2);
		ALBEDO = ground_color*(1.0-blackness);
	}
	// Transform to clip space
    vec4 view_space_position = modelview * vec4(p, 1.0);
    vec4 clip_space_position = PROJECTION_MATRIX * view_space_position;
    // Compute depth
    float ndc_depth = clip_space_position.z / clip_space_position.w;
    DEPTH = ndc_depth * 0.5 + 0.5; // Map from [-1, 1] to [0, 1]
	DEPTH = pow(DEPTH, 9.0);
	//NORMAL = n;
	//max(min((rd - camera_direction).x, 1.0), 0.0);
	//ALBEDO = vec3(1.)*DEPTH; 
}


void light() {
	DIFFUSE_LIGHT += 0.3 * ATTENUATION * LIGHT_COLOR * clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	//SPECULAR_LIGHT = vec3(0.);
}
