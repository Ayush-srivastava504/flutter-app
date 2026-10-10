"""Prototype of the ClipForge export filter graph. The Dart builder (lib/export/export_command_builder.dart)
is a line-by-line port of build_export(); run verify.py to prove the graph against real FFmpeg."""
import math
FPS=30; MAX_T=600; FADE_T=300; REF_W=360; AR=44100

def even(n): n=int(round(n)); return n if n%2==0 else n+1
def dims(aspect, short):
    if aspect<=1: return even(short), even(short/aspect)
    return even(short*aspect), even(short)
def esc_path(p): return p.replace('\\','\\\\').replace(':','\\:').replace("'","\\'")
def sec(ms): return f"{ms/1000:.3f}"

def boundary(clips, i):
    """Return (kind, ms) for the boundary after clip i. kind in cut|fade|dissolve."""
    if i>=len(clips)-1: return ('cut',0)
    a=clips[i]['end']-clips[i]['start']; b=clips[i+1]['end']-clips[i+1]['start']
    k=clips[i].get('transition','cut')
    if k=='dissolve':
        t=min(MAX_T,a//2,b//2); return ('dissolve',t) if t>=100 else ('cut',0)
    if k=='fade':
        t=min(FADE_T,a//2,b//2); return ('fade',t) if t>=50 else ('cut',0)
    return ('cut',0)

def build_export(clips, overlays, music, aspect, short, out, encoder, fonts, textfiles, music_path=None):
    W,H=dims(aspect,short); n=len(clips); args=[]; inputs=[]
    durs=[c['end']-c['start'] for c in clips]
    for c,d in zip(clips,durs):
        if c['photo']: inputs += ['-loop','1','-framerate',str(FPS),'-t',sec(d),'-i',c['path']]
        else: inputs += ['-i',c['path']]
    if music: inputs += ['-i',music['path']]
    bounds=[boundary(clips,i) for i in range(n)]
    f=[]
    for i,c in enumerate(clips):
        d=durs[i]; ch=[]
        if not c['photo']: ch.append(f"trim=start={sec(c['start'])}:end={sec(c['end'])},setpts=PTS-STARTPTS")
        ch += [f"fps={FPS}", f"scale={W}:{H}:force_original_aspect_ratio=decrease",
               f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=black","setsar=1"]
        b,ct,s=c.get('brightness',0),c.get('contrast',0),c.get('saturation',0)
        if b or ct or s: ch.append(f"eq=brightness={b:.3f}:contrast={1+ct:.3f}:saturation={1+s:.3f}")
        ch.append("format=yuv420p")
        inb=bounds[i-1] if i>0 else ('cut',0); outb=bounds[i]
        if inb[0]=='fade': ch.append(f"fade=t=in:st=0:d={sec(inb[1])}")
        if outb[0]=='fade': ch.append(f"fade=t=out:st={sec(d-outb[1])}:d={sec(outb[1])}")
        ch.append("settb=AVTB")
        f.append(f"[{i}:v]"+",".join(ch)+f"[v{i}]")
        # audio
        if c.get('has_audio') and not c['photo']:
            vol=0 if c.get('muted') else c.get('volume',1.0)
            a=[f"atrim=start={sec(c['start'])}:end={sec(c['end'])}","asetpts=PTS-STARTPTS",f"aresample={AR}",
               "aformat=sample_fmts=fltp:channel_layouts=stereo",f"volume={vol:.3f}"]
            src=f"[{i}:a]"
        else:
            a=[f"anullsrc=r={AR}:cl=stereo","aformat=sample_fmts=fltp:channel_layouts=stereo",f"atrim=0:{sec(d)}","asetpts=PTS-STARTPTS"]
            src=""
        if inb[0]=='fade': a.append(f"afade=t=in:st=0:d={sec(inb[1])}")
        if outb[0]=='fade': a.append(f"afade=t=out:st={sec(d-outb[1])}:d={sec(outb[1])}")
        f.append(src+",".join(a)+f"[a{i}]")
    cv,ca,D='v0','a0',durs[0]; overlaps=[]  # (original boundary ms, overlap ms)
    orig=durs[0]
    for i in range(1,n):
        kind,t=bounds[i-1]
        if kind=='dissolve':
            f.append(f"[{cv}][v{i}]xfade=transition=fade:duration={sec(t)}:offset={sec(D-t)},settb=AVTB,setpts=PTS-STARTPTS[x{i}]")
            f.append(f"[{ca}][a{i}]acrossfade=d={sec(t)}:c1=tri:c2=tri[ax{i}]")
            D+=durs[i]-t; overlaps.append((orig,t))
        else:
            f.append(f"[{cv}][v{i}]concat=n=2:v=1:a=0,settb=AVTB[x{i}]")
            f.append(f"[{ca}][a{i}]concat=n=2:v=0:a=1[ax{i}]")
            D+=durs[i]
        orig+=durs[i]; cv,ca=f'x{i}',f'ax{i}'
    def remap(t): return max(0,min(D,t-sum(o for b,o in overlaps if b<=t)))
    k=0
    for o in overlays:
        s,e=remap(o['start']),remap(o['end'])
        if e<=s or not o['content'].strip(): continue
        col=o['color']; al=((col>>24)&255)/255; rgb=col&0xFFFFFF
        fs=max(8,round(o['size']*W/REF_W)); font=fonts.get(o.get('font','Default'),fonts['Default'])
        nx=f"t{k}"
        f.append(f"[{cv}]drawtext=fontfile='{esc_path(font)}':textfile='{esc_path(textfiles[o['id']])}':expansion=none:"
                 f"fontsize={fs}:fontcolor=0x{rgb:06X}@{al:.2f}:shadowcolor=black@0.6:shadowx=2:shadowy=2:"
                 f"x={o['x']:.4f}*w-text_w/2:y={o['y']:.4f}*h-text_h/2:enable='between(t,{sec(s)},{sec(e)})'[{nx}]")
        cv=nx; k+=1
    ao=ca
    if music:
        mi=n; ms=music['start']; me=music['end']; off=remap(music['offset'])
        f.append(f"[{mi}:a]atrim=start={sec(ms)}:end={sec(me)},asetpts=PTS-STARTPTS,aresample={AR},"
                 f"aformat=sample_fmts=fltp:channel_layouts=stereo,volume={music['volume']:.3f},adelay={off}:all=1[mus]")
        f.append(f"[{ca}][mus]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.97[aout]")
        ao='aout'
    args=['-y']+inputs+['-filter_complex',';'.join(f),'-map',f'[{cv}]','-map',f'[{ao}]']+encoder+[
        '-pix_fmt','yuv420p','-r',str(FPS),'-c:a','aac','-b:a','192k','-ar',str(AR),'-movflags','+faststart',out]
    return args,D,(W,H)
