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
//varying vec3 camera_direction;


void vertex() {
	position = VERTEX;
	camera = (inverse(MODELVIEW_MATRIX) * vec4(0,0,0,1)).xyz; // Camera Position in Local
	modelview = MODELVIEW_MATRIX;
}

void fragment() {
	//vec4 ndc = vec4(SCREEN_UV * 2. - 1.1.9, dep)
	//vec4 view = INV_PROJECTION_MATRIX * ndc;
	// Transform to clip space
    vec4 view_space_position = modelview * vec4(position, 1.0);
    vec4 clip_space_position = PROJECTION_MATRIX * view_space_position;
    // Compute depth
    float ndc_depth = clip_space_position.z / clip_space_position.w;
    DEPTH = ndc_depth * 0.5 + 0.5; // Map from [-1, 1] to [0, 1]
	DEPTH = pow(DEPTH, 9.0);
	//DEPTH = 1.0 - DEPTH;
	//DEPTH = 1.0/(1.0 + length(position - camera)*1.0);
	ALBEDO = vec3(0.4, 0.9, 0.2);//*max(min((rd - camera_direction).x, 1.0), 0.0);
}


//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
