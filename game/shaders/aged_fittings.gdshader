shader_type spatial;
uniform vec4 paint : source_color = vec4(0.18,0.22,0.19,1.0);
varying vec3 wp;
varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=normalize(mat3(MODEL_MATRIX)*NORMAL);}
float hash(vec2 p) { vec3 q=fract(vec3(p.xyx)*0.1031); q+=dot(q,q.yzx+33.33); return fract((q.x+q.y)*q.z); }
float noise(vec2 p) { vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void fragment(){
 vec2 p=abs(wn.x)>0.7 ? wp.zy : wp.xy;
 float grain=noise(p*85.0);
 float chips=smoothstep(0.82,0.95,noise(p*160.0)+noise(p*13.0)*0.08);
 float grime=smoothstep(0.35,0.78,noise(vec2(p.x*5.0,p.y*0.8)));
 vec3 old_paint=paint.rgb*mix(0.9,1.08,grain);
 ALBEDO=mix(old_paint,vec3(0.18,0.16,0.11),chips*0.45);
 ALBEDO*=1.0-grime*0.22;
 ROUGHNESS=0.86;
 METALLIC=chips*0.12;
 SPECULAR=0.15;
}
