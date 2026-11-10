shader_type spatial;
render_mode cull_disabled;
uniform bool traffic_symbol = false;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
 float n=noise(UV*32.0);
 float rust=1.0-smoothstep(0.015,0.10,edge+n*0.045);
 rust=max(rust,smoothstep(0.73,0.86,noise(UV*90.0))*0.5);
 float rim=(1.0-smoothstep(0.022,0.027,edge))*smoothstep(0.006,0.012,edge);
 vec3 enamel=vec3(0.76,0.72,0.57)*(0.88+0.12*noise(UV*17.0));
 if (traffic_symbol) {
  vec2 p=UV-vec2(0.5); float radius=length(p);
  if(radius>0.495) { discard; }
  edge=0.5-radius;
  rust=1.0-smoothstep(0.008,0.065,edge+n*0.022);
  float red=step(0.35,radius);
  red=max(red,(1.0-step(0.046,abs(p.x-p.y)))*step(radius,0.43));
  red=max(red,(1.0-step(0.046,abs(p.x+p.y)))*step(radius,0.43));
  float letter=(1.0-step(0.05,abs(p.x+0.115)))*step(abs(p.y),0.23);
  letter=max(letter,(1.0-step(0.042,abs(abs(p.y)-0.19)))*step(abs(p.x),0.16));
  letter=max(letter,(1.0-step(0.035,abs(p.y)))*step(abs(p.x),0.14));
  enamel=mix(enamel,vec3(0.08,0.09,0.075),letter);
  enamel=mix(enamel,vec3(0.49,0.12,0.045),red);
  rim=0.0;
 }
 enamel=mix(enamel,vec3(0.34,0.12,0.055),rim);
 vec3 color=mix(enamel,vec3(0.26,0.105,0.036)*(0.65+n),rust);
 float scratches=step(0.985,noise(UV*vec2(220.0,20.0)));
 ALBEDO=mix(color,vec3(0.43,0.39,0.29),scratches*0.4);
 ROUGHNESS=0.82;
}
