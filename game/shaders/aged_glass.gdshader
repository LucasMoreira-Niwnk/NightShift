shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform vec4 paint : source_color = vec4(0.3,0.32,0.28,1.0);
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash(vec2 p) { vec3 q=fract(vec3(p.xyx)*0.1031); q+=dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
float noise(vec2 p) { vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void fragment(){
 float edge=1.0-smoothstep(0.01,0.17,min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y)));
 float streak=noise(vec2((wp.x+wp.z)*19.0,wp.y*0.6));
 float haze=smoothstep(0.52,0.83,noise(vec2(wp.x+wp.z,wp.y)*4.0));
 float deposit=edge*(0.6+streak*0.4);
 ALBEDO=mix(paint.rgb,vec3(0.34,0.31,0.23),deposit);
 ALPHA=0.065+deposit*0.25+haze*0.045;
 ROUGHNESS=0.42+deposit*0.3;
 SPECULAR=0.22;
}
