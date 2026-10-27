shader_type spatial;
render_mode cull_back;
uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.4, 0.43, 0.36, 1.0);
uniform int pattern = 0;
uniform bool upper_layout = false;
uniform bool facade_faces = false;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void vertex() { wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(mat3(MODEL_MATRIX)*NORMAL); }
void fragment() {
 vec2 p=wp.xz;
 if(abs(wn.x)>0.7) p=wp.zy;
 else if(abs(wn.z)>0.7) p=wp.xy;
 int style=pattern;
 vec3 color=tint.rgb;
 if(upper_layout) {
  if(wp.x < -1.6 && wp.z < -4.0) {style=3; color=vec3(0.3,0.22,0.13);}
  else if(wp.x < -1.6) {style=1; color=vec3(0.19,0.28,0.26);}
  else if(wp.x > 1.6) {style=3; color=vec3(0.35,0.28,0.18);}
  else {style=0; color=vec3(0.42,0.44,0.37);}
 }
 if(facade_faces && ((wp.x>7.9 && wn.x>0.7) || (wp.x < -7.9 && wn.x < -0.7) || (wp.z > 11.9 && wn.z > 0.7))) { style=4; color=vec3(0.37,0.34,0.27); }
 vec2 uv=p*0.65;
 vec3 grain=texture(base_color,uv).rgb;
 float mottling=noise(p*0.5)*0.22 + noise(p*3.1)*0.08;
 float seam=0.0;
 if(style==0 || style==1) {
  vec2 cell=p/(style==0 ? 0.6 : 0.45);
  vec2 edge=min(fract(cell),1.0-fract(cell));
  seam=1.0-smoothstep(0.008,0.02,min(edge.x,edge.y));
  color*=0.84+0.22*hash(floor(cell));
  if(style==1) grain=mix(vec3(0.7),grain,0.24);
 } else if(style==2) {
  grain=mix(vec3(0.65),grain,0.35);
  float crack=abs(noise(p*1.3)-0.52);
  seam=(1.0-smoothstep(0.001,0.009,crack))*0.65;
 } else if(style==3) {
  vec2 boards=vec2(p.x*6.0,p.y*0.8+floor(p.x*6.0)*0.5);
  vec2 edge=min(fract(boards),1.0-fract(boards));
  seam=1.0-smoothstep(0.008,0.026,min(edge.x,edge.y));
  grain=vec3(0.58+0.16*sin(p.y*30.0+noise(p*2.0)*7.0));
  color*=0.75+0.4*hash(floor(boards));
 } else if(style==4) {
  vec2 bricks=vec2(p.x/0.42+mod(floor(p.y/0.19),2.0)*0.5,p.y/0.19);
  vec2 edge=min(fract(bricks),1.0-fract(bricks));
  seam=1.0-smoothstep(0.015,0.05,min(edge.x,edge.y));
  color*=0.82+0.25*hash(floor(bricks));
  color=mix(color,vec3(0.23,0.29,0.20),smoothstep(0.65,0.86,noise(p*1.4))*0.55);
 }
 vec3 result=color*mix(vec3(0.75),grain,0.35)*(0.82+mottling);
 result=mix(result,style==4?vec3(0.19,0.2,0.16):vec3(0.055,0.065,0.05),seam*0.65);
 // Moisture runs and worn lower wall paint; no glowing grime.
 if(abs(wn.y)<0.3) result*=mix(0.65,1.0,smoothstep(0.0,1.2,mod(wp.y,4.2))) + noise(vec2(p.x*4.0,p.y*0.4))*0.12;
 ALBEDO=result;
 ROUGHNESS=clamp(texture(rough_map,uv).r*0.3+0.65,0.65,1.0);
 SPECULAR=0.18;
}
