shader_type spatial;
render_mode cull_back;
uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D base_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D facade_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D facade_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D broken_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D broken_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dust_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wood_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wood_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mud_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(0.88, 0.85, 0.74, 1.0);
uniform float texture_scale = 0.45;
uniform int pattern = 0;
uniform bool upper_layout = false;
uniform bool facade_faces = false;
uniform bool force_facade = false;
uniform bool outdoor_ground = false;
varying vec3 wp;
varying vec3 wn;
// Sin-free hash avoids large-coordinate precision bands on broad surfaces.
float hash(vec2 p) {
 vec3 q=fract(vec3(p.xyx)*0.1031);
 q+=dot(q,q.yzx+33.33);
 return fract((q.x+q.y)*q.z);
}
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) { return noise(p)*0.57+noise(p*2.03)*0.28+noise(p*4.1)*0.15; }
float floor_edge() {
 float d=2.0-abs(wp.x);
 if(wp.y<1.0) {
  if(wp.z>4.0) d=min(8.0-abs(wp.x),min(wp.z-4.0,12.0-wp.z));
  else if(wp.x < -2.0 && wp.z > -2.0) d=min(min(wp.x+8.0,-2.0-wp.x),min(wp.z+2.0,4.0-wp.z));
  else if(wp.x > 2.0) d=min(min(wp.x-2.0,8.0-wp.x),min(wp.z+10.0,-2.0-wp.z));
  else if(wp.x < -2.0) d=min(min(wp.x+8.0,-2.0-wp.x),min(wp.z+14.0,-6.0-wp.z));
 } else {
  d=1.6-abs(wp.x);
  if(wp.x < -1.6) d=min(wp.x+8.0,-1.6-wp.x);
  else if(wp.x > 1.6) d=min(wp.x-1.6,8.0-wp.x);
 }
 return max(d,0.0);
}
void vertex() { wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(mat3(MODEL_MATRIX)*NORMAL); }
void fragment() {
 bool wall=abs(wn.y)<0.4;
 vec2 p=wp.xz;
 if(abs(wn.x)>0.7) p=wp.zy;
 else if(abs(wn.z)>0.7) p=wp.xy;
 vec2 uv=p*texture_scale;
 vec3 color=texture(base_color,uv).rgb*tint.rgb;
 vec3 bump=texture(base_normal,uv).xyz*2.0-1.0;
 int style=pattern;
 if(upper_layout) {
  if(wp.x < -1.6 && wp.z < -5.0) style=3;
  else if(wp.x < -1.6) {style=1; color=texture(dust_color,p*0.42).rgb*vec3(0.7,0.85,0.73);}
  else if(wp.x > 1.6) style=3;
 }
 if(style==3) {
  color=texture(wood_color,p*1.3).rgb*vec3(0.84,0.8,0.68);
  bump=texture(wood_normal,p*1.3).xyz*2.0-1.0;
 }
 if(style==1) {
  vec2 edge=min(fract(p/0.45),1.0-fract(p/0.45));
  color*=mix(0.72,1.0,smoothstep(0.004,0.014,min(edge.x,edge.y)));
 }
 bool main_shell=(wp.x>7.75 && wn.x>0.7) || (wp.x < -7.75 && wn.x < -0.7 && (wp.z>3.2 || wp.z< -10.7)) || (wp.z>9.85 && wn.z>0.7) || (wp.z < -15.8 && wn.z < -0.7);
 bool stair_shell=(wp.z< -16.0 && abs(wp.x)>2.85 && abs(wp.x)<3.2 && wn.x*wp.x>0.7) || (wp.x< -8.2 && ((wp.z< -10.4 && wn.z< -0.7) || (wp.z>2.85 && wn.z>0.7) || (wp.x< -14.1 && wn.x< -0.7)));
 bool exterior=force_facade || (facade_faces && (main_shell || stair_shell));
 float dirt=0.0;
 if(exterior) {
  // Faded mineral render, with local water tracks rather than a dark soot coat.
  vec2 fuv=p*0.43;
  float moisture=smoothstep(0.3,0.68,fbm(vec2(p.x*1.7,p.y*0.19)+vec2(3.0,9.0)));
  float rising=1.0-smoothstep(0.0,1.1,mod(wp.y,4.2));
  vec3 plaster=texture(base_color,fuv).rgb*vec3(0.84,0.85,0.79);
  vec3 weathered=texture(facade_color,fuv*0.91).rgb;
  // Keep the substrate readable, even where algae have settled.
  weathered=mix(plaster,weathered,0.58);
  color=mix(plaster,weathered,clamp(0.32+moisture*0.45+rising*0.3,0.0,0.82));
  // Faded upper-storey paint and warm ground-floor render separate the volumes.
  color*=wp.y>4.1 ? vec3(0.78,0.85,0.8) : vec3(0.94,0.88,0.76);
  color*=1.0-moisture*0.12-rising*0.06;
  float chip=smoothstep(0.68,0.84,fbm(p*0.8+12.3))*0.16;
  color=mix(color,texture(broken_color,fuv).rgb,chip);
  bump=texture(base_normal,fuv).xyz*2.0-1.0;
  bump*=0.5;
 } else if(wall) {
  // Photograph carries the cracks; broad layers add peeling and rising damp.
  float peeled=smoothstep(0.68,0.85,fbm(p*0.37+12.0))*0.25;
  color=mix(color,texture(broken_color,p*0.42).rgb*vec3(0.83,0.8,0.69),peeled);
  float damp=(1.0-smoothstep(0.15,1.0,mod(wp.y,4.2)))*0.65;
  damp=max(damp,smoothstep(0.57,0.75,fbm(vec2(p.x*3.2,p.y*0.25)))*0.55);
  color=mix(color,color*vec3(0.32,0.37,0.24),damp);
 } else if(style==6) {
  // Lime-painted ceiling: faint water halos and hairline cracks, no floor dirt.
  float damp=smoothstep(0.58,0.79,fbm(p*0.48+vec2(31.0,7.0)));
  color=mix(color,color*vec3(0.78,0.75,0.66),damp*0.4);
  bump*=0.18;
 } else if(wn.y>0.5 && !outdoor_ground) {
  float corner=exp(-floor_edge()*2.6);
  float patches=smoothstep(0.35,0.72,fbm(p*0.62+vec2(9.2,3.8)));
  dirt=clamp(0.04+patches*0.27+corner*0.25,0.0,0.58);
  // A broken, trodden path leaves heavier dust beside the walls.
  if(abs(wp.x)<0.7) dirt*=0.55;
  vec3 powder=mix(vec3(0.52,0.48,0.38),texture(dust_color,p*0.34+vec2(0.1,0.8)).rgb*vec3(0.78,0.72,0.58),0.3);
  color=mix(color,mix(color,powder,0.55),dirt);
  float stains=smoothstep(0.61,0.80,fbm(p*0.72-15.0))*0.18;
  color*=1.0-stains;
 }
 if(outdoor_ground) {
  float encroach=smoothstep(0.64,0.84,fbm(p*0.24+vec2(2.0,8.4)))*0.35;
  encroach=max(encroach,smoothstep(20.0,29.0,abs(wp.x))*0.8);
  color=mix(color,texture(mud_color,p*0.7).rgb*vec3(0.82,0.85,0.7),encroach);
  bump=mix(bump,texture(mud_normal,p*0.7).xyz*2.0-1.0,encroach);
 }
 float wet=0.0;
 if(outdoor_ground) {
  // Shallow water retains the asphalt below it; feathered, irregular banks.
  vec2 q=(wp.xz-vec2(3.5,24.0))/vec2(2.2,1.15);
  vec2 q2=(wp.xz-vec2(-14.0,23.0))/vec2(1.7,1.2);
  vec2 q3=(wp.xz-vec2(20.0,29.0))/vec2(2.6,1.4);
  float basin=min(length(q),min(length(q2),length(q3)));
  float bank=basin+fbm(p*2.1)*0.5+noise(p*7.0)*0.12;
  wet=1.0-smoothstep(0.82,1.22,bank);
  color*=mix(1.0,0.78,wet);
  bump*=mix(1.0,0.2,wet);
 }
 bump*=mix(1.0,0.25,dirt);
 vec3 tangent=abs(wn.x)>0.7 ? vec3(0,0,1) : vec3(1,0,0);
 vec3 bitangent=wall ? vec3(0,1,0) : vec3(0,0,1);
 NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(wn+tangent*bump.x*0.72+bitangent*bump.y*0.72));
 ALBEDO=max(color,vec3(0.012));
 ROUGHNESS=mix(clamp(texture(rough_map,uv).r,0.76,1.0),1.0,dirt);
 ROUGHNESS=mix(ROUGHNESS,0.32,wet);
 AO=mix(1.0,texture(ao_map,uv).r,0.4);
 AO_LIGHT_AFFECT=0.5;
 SPECULAR=wall ? 0.10 : mix(0.06,0.24,wet);
}
