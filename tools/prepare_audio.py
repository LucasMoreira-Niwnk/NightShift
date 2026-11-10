"""Offline asset preparation for NIGHTSHIFT. Requires ffmpeg + numpy (authoring only).
Reads the downloaded CC0 originals from .local/audio-sources; never used at runtime.
See game/assets/audio/vesper/SOURCES.md for authors, URLs and source file names.
"""
from pathlib import Path
import hashlib, json, shutil, subprocess, wave
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / ".local/audio-sources"
OUT = ROOT / "game/assets/audio/vesper"
RATE = 22050
FF = shutil.which("ffmpeg")
manifest = []

def read(name, low=8000, high=65):
    data = subprocess.check_output([FF, "-v", "error", "-i", str(SRC/name), "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-" ])
    x = np.frombuffer(data, dtype="<f4").astype(float)
    x -= x.mean()
    f = np.fft.rfftfreq(len(x), 1/RATE)
    # Smooth frequency rolloffs avoid the ringing of a brick-wall cut.
    gain = 1/(1+(f/low)**4) * (1 - 1/(1+(f/max(high,1))**4))
    return np.fft.irfft(np.fft.rfft(x)*gain, n=len(x))

def trim(x):
    energy = np.convolve(x*x, np.ones(220)/220, mode="same")
    active = np.where(energy > max(energy.max()*.004, 1e-9))[0]
    return x[max(0,active[0]-220):min(len(x),active[-1]+1100)] if len(active) else x

def fade(x, seconds=.012):
    x=x.copy(); n=min(int(seconds*RATE), len(x)//2)
    x[:n]*=np.linspace(0,1,n); x[-n:]*=np.linspace(1,0,n)
    return x

def loop(x, seconds=.25):
    n=min(int(seconds*RATE),len(x)//4)
    y=x[n:].copy(); t=np.linspace(0,1,n)
    y[-n:]=x[-n:]*(1-t)+x[:n]*t
    return y

def save(name,x,sources,looped=False):
    OUT.mkdir(parents=True,exist_ok=True)
    x=loop(x) if looped else fade(x)
    # Consistent headroom; game mix provides the acoustic distance and hierarchy.
    x=x/max(abs(x).max(),1e-9)*(.5 if looped else .7)
    raw=np.round(x*32767).astype("<i2").tobytes()
    dest=OUT/(name+".wav")
    with wave.open(str(dest),"wb") as w:
        w.setparams((1,2,RATE,0,"NONE","not compressed")); w.writeframes(raw)
    manifest.append(dict(file=dest.name,seconds=round(len(x)/RATE,3),loop=looped,
        peak_db=round(20*np.log10(abs(x).max()),2),sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),
        sources=[dict(file=s,sha256=hashlib.sha256((SRC/s).read_bytes()).hexdigest()) for s in sources]))

save("rain",read("water/loop_rain.ogg",7000,100),["water/loop_rain.ogg"],True)
save("rain_inside",read("water/loop_rain.ogg",950,120),["water/loop_rain.ogg"],True)
save("hum",read("fan.ogg",1800,70),["fan.ogg"],True)
for i in range(6):
    s=f"steps{i}.ogg"; save(f"step_hard_{i}",trim(read(s,6500,90)),[s])
x=read("woodsteps0.wav",6000,90)
# Extract individual footfalls, with enough spacing to retain their wooden decay.
energy=np.convolve(x*x,np.ones(220)/220,mode="same")
peaks=[]
for j in np.argsort(energy)[::-1]:
    if all(abs(int(j)-k)>RATE*.40 for k in peaks): peaks.append(int(j))
    if len(peaks)==4: break
for i,k in enumerate(sorted(peaks)):
    save(f"step_wood_{i}",x[max(0,k-880):min(len(x),k+int(.28*RATE))],["woodsteps0.wav"])
for name,source in [("door_open","foley/door_open.ogg"),("door_close","foley/door_close_02.ogg"),
                    ("switch","foley/switch_01.ogg"),("knock","wood-metal/wood_hit_02.ogg")]:
    save(name,trim(read(source,5500,85)),[source])
# Layer three irregular wood-friction strokes across the 1.5 s chair animation.
friction=["wood-metal/wood_squeak_01.ogg", "wood-metal/wood_squeak_02.ogg"]
drag=np.zeros(int(1.5*RATE))
for source,offset,speed,gain in [(friction[0],0,.85,.8),(friction[1],.48,.75,1),(friction[0],.95,.95,.6)]:
    x=trim(read(source,3500,110))
    x=fade(np.interp(np.arange(0,len(x),speed),np.arange(len(x)),x),.025)*gain
    start=int(offset*RATE); n=min(len(x),len(drag)-start); drag[start:start+n]+=x[:n]
save("drag",drag,friction)
x=trim(read("phone.ogg",6200,200))
# One ring only: the narrative decides when to ring again.
save("ring",x[:int(1.45*RATE)],["phone.ogg"])
x=trim(read("printer.ogg",6500,120)); save("printer",x[:int(4.5*RATE)],["printer.ogg"])
x=trim(read("car.ogg",3500,65)); save("engine",x[-int(3.2*RATE):],["car.ogg"])
save("car_door",trim(read("foley/door_close_04.ogg",2400,70)),["foley/door_close_04.ogg"])
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
print(f"Prepared {len(manifest)} mono PCM cues; {sum((OUT/m['file']).stat().st_size for m in manifest)/1048576:.2f} MiB")
