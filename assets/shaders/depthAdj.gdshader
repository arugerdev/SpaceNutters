shader_type spatial;


//positive depth moves toward the camera in world units
uniform float depth_offset = 0.0;


//offset object by world coordinates
//towards the camera. FRAGMENT version

void fragment() {
	//view to world(global) fragment position set to world_position
	vec3 world_position = vec4(INV_VIEW_MATRIX * vec4(VERTEX,1)).xyz;
	//set direction fragment from vertex to camera in world space
	vec3 dir2cam  = normalize(CAMERA_POSITION_WORLD - world_position);
	//move fragment towards camera in world(global) space
	world_position += dir2cam * depth_offset;
	//transform world_position from world(global) to view space
	//then transform world_position from view to clip(ndc) space
	vec4 ndc_offset = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_position,1);
	//normalize ndc_offset.z and set depth
	DEPTH = ndc_offset.z/ndc_offset.w;
}



//NOTE:
//This shader does not correct for FoV or Scale.
//if the offset is too large, or the FoV is too wide
//these artifacts become more pronounced.