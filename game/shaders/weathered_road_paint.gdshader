shader_type spatial;
render_mode cull_disabled;
uniform sampler2D dirt : filter_linear_mipmap, repeat_enable;
varying vec3 wp;
void vertex(){ wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float wear=texture(dirt,wp.xz*0.65).r;
 float scratches=fract(sin(dot(floor(wp.xz*35.0),vec2(13.4,35.2)))*1245.5);
 ALBEDO=vec3(0.34,0.31,0.19)*(0.5+wear*0.5);
 ROUGHNESS=1.0;
 SPECULAR=0.0;
 ALPHA=wear*(0.5+scratches*0.5);
 ALPHA_SCISSOR_THRESHOLD=0.52;
}
