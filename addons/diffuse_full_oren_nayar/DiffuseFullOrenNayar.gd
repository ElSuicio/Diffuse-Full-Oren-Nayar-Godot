@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeDiffuseFullOrenNayar

# CC0 1.0 Universal, ElSuicio, 2025.
# GODOT v4.4.1.stable.
# x.com/ElSuicio
# github.com/ElSuicio
# Contact email [interdreamsoft@gmail.com]

func _get_name() -> String:
	return "FullOrenNayar"

func _get_category() -> String:
	return "Lightning/Diffuse"

func _get_description() -> String:
	return "Oren-Nayar Diffuse Reflectance Model."

func _get_return_icon_type() -> PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _is_available(mode : Shader.Mode, type : VisualShader.Type) -> bool:
	if( mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_LIGHT ):
		return true
	else:
		return false

#region Input
func _get_input_port_count() -> int:
	return 6

func _get_input_port_name(port : int) -> String:
	match port:
		0:
			return "Normal"
		1:
			return "Light"
		2:
			return "View"
		3:
			return "Light Color"
		4:
			return "Attenuation"
		5:
			return "Roughness"
	
	return ""

func _get_input_port_type(port : int) -> PortType:
	match port:
		0:
			return PORT_TYPE_VECTOR_3D # Normal.
		1:
			return PORT_TYPE_VECTOR_3D # Light.
		2:
			return PORT_TYPE_VECTOR_3D # View.
		3:
			return PORT_TYPE_VECTOR_3D # Light Color.
		4:
			return PORT_TYPE_SCALAR # Attenuation.
		5:
			return PORT_TYPE_SCALAR # Roughness.
	
	return PORT_TYPE_SCALAR

#endregion

#region Output
func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port : int) -> String:
	return "Diffuse"

func _get_output_port_type(_port : int) -> PortType:
	return PORT_TYPE_VECTOR_3D

#endregion

func _get_code(input_vars : Array[String], output_vars : Array[String], _mode : Shader.Mode, _type : VisualShader.Type) -> String:
	var default_vars : Array[String] = [
		"NORMAL",
		"LIGHT",
		"VIEW",
		"LIGHT_COLOR",
		"ATTENUATION",
		"ROUGHNESS"
		]
	
	for i in range(0, input_vars.size(), 1):
		if(!input_vars[i]):
			input_vars[i] = default_vars[i]
	
	var shader : String = """
	const float INV_PI = 0.318309;
	
	vec3 n = normalize( {normal} );
	vec3 l = normalize( {light} );
	vec3 v = normalize( {view} );
	
	float NdotL = dot(n, l); // [-1.0, 1.0].
	float NdotV = dot(n, v); // [-1.0, 1.0].
	
	float LdotV = dot(l, v); // [-1.0, 1.0].
	
	float cNdotL = max(NdotL, 0.0); // [0.0, 1.0].
	float cNdotV = max(NdotV, 0.0); // [0.0, 1.0].
	
	float cLdotV = max(LdotV, 0.0); // [0.0, 1.0].
	
	// https://dl.acm.org/doi/pdf/10.1145/192161.192213
	
	float a = {roughness} * {roughness}; // Variance.
	
	vec3 r = 2.0 * cNdotL * n - l; // Radiance.
	
	float NdotR = dot(n, r);
	
	float theta_i = min(acos(cNdotL), 1e-4);
	float theta_r = min(acos(NdotR), 1e-4);
	
	vec3 l_proj = normalize(l - cNdotL * n);
	vec3 v_proj = normalize(v - cNdotV * n + 1.0);
	
	float cos_phi = dot(l_proj, v_proj);
	
	float alpha = max(theta_i, theta_r);
	float beta = min(theta_i, theta_r);
	
	float C1 = 1.0 - 0.5 * ( a / (a + 0.33) );
	
	float C2 = mix(
		0.45 * ( a / (a + 0.09) ) * sin(alpha),
		0.45 * ( a / (a + 0.09) ) * ( sin(alpha) - pow((2.0 * beta) / PI, 3.0)),
		step(0.0, cos_phi)
	);
	
	float C3 = 0.125 * ( a / (a + 0.09) ) * pow((4.0 * alpha * beta) / (PI * PI), 2.0);
	
	float L1 = cos(theta_i) * (C1 + C2 * cos_phi * tan(beta) + C3 * (1.0 - abs(cos_phi)) * tan((alpha + beta) / 2.0) );
	float L2 = 0.17 * cos(theta_i) * ( (a) / (a + 0.13) ) * ((1.0 - cos_phi) * pow((2.0 * beta) / PI, 2.0));
	
	float diffuse_oren_nayar = max(min(L1 + L2, 1.0), 0.0) * cNdotL;
	
	{output} = {light_color} * {attenuation} * diffuse_oren_nayar * INV_PI;
	"""
	
	return shader.format({
		"normal" : input_vars[0],
		"light" : input_vars[1],
		"view" : input_vars[2],
		"light_color" : input_vars[3],
		"attenuation" : input_vars[4],
		"roughness" : input_vars[5],
		"output" : output_vars[0]
		})
