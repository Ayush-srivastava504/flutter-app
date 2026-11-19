"""Python mirror of the ClipForge export filter graph (lib/export/export_command_builder.dart).
Run verify_export_graph.py to prove the graph against a real FFmpeg. Keep the two builders in step:
any change to the Dart builder must be made here too."""
FPS=30; MAX_T=600; FADE_T=300; REF_W=360; AR=44100

# transitionOut id -> xfade name (None = not an overlapping transition). Mirrors transition_x.dart.
XFADE={'dissolve':'fade','slideleft':'slideleft','wipeleft':'wipeleft','circleopen':'circleopen','zoomin':'zoomin'}

# Look matrices: the 9 RGB mix coefficients, row-major. Mirrors look_x.dart (bias-free on purpose).
LOOKS={
    'mono':   [0.2126,0.7152,0.0722, 0.2126,0.7152,0.0722, 0.2126,0.7152,0.0722],
    'sepia':  [0.393,0.769,0.189, 0.349,0.686,0.168, 0.272,0.534,0.131],
    'vintage':[0.75,0.20,0.05, 0.10,0.70,0.20, 0.15,0.20,0.55],
    'cool':   [0.85,0.05,0.0, 0.0,0.95,0.05, 0.0,0.10,1.05],
    'warm':   [1.05,0.08,0.0, 0.0,1.0,0.0, 0.0,0.0,0.88],
}

def even(n): n=int(round(n)); return n if n%2==0 else n+1
def dims(aspect, short):
    if aspect<=1: return even(short), even(short/aspect)
    return even(short*aspect), even(short)
def esc_path(p): return p.replace('\\','\\\\').replace(':','\\:').replace("'","\\'")
def sec(ms): return f"{ms/1000:.3f}"
def color(argb): return f"0x{argb&0xFFFFFF:06X}@{((argb>>24)&255)/255:.2f}"

def speed_of(c):
    s=c.get('speed',1.0)
    return 1.0 if c['photo'] or s<=0 else s

def dur(c):
    """Timeline length of a clip: source span / speed."""
    raw=c['end']-c['start']; s=speed_of(c)
    return raw if s==1.0 else int(round(raw/s))

def atempo_chain(speed):
    if speed<=0 or speed==1.0: return []
    out=[]; rest=speed
    while rest>2.0: out.append('atempo=2.000'); rest/=2.0
    while rest<0.5: out.append('atempo=0.500'); rest/=0.5
    if abs(rest-1.0)>0.0005: out.append(f"atempo={rest:.3f}")
    return out

def rotate_flip(c):
    h=bool(c.get('flip_h')); v=bool(c.get('flip_v')); tr=None
    t=c.get('turns',0)%4
    if t==1: tr='transpose=1'
    elif t==2: h=not h; v=not v
    elif t==3: tr='transpose=2'
    return (['hflip'] if h else [])+(['vflip'] if v else [])+([tr] if tr else [])

def color_matrix(b,c,s):
    """Same 4x5 matrix as color_filter_x.dart buildColorMatrix: saturation -> contrast -> brightness."""
    cl=lambda v:max(-1.0,min(1.0,v))
    sv=1+cl(s); lr,lg,lb=0.213,0.715,0.072
    S=[[lr+(1-lr)*sv,lg-lg*sv,lb-lb*sv,0],[lr-lr*sv,lg+(1-lg)*sv,lb-lb*sv,0],[lr-lr*sv,lg-lg*sv,lb+(1-lb)*sv,0]]
    cv=1+cl(c); t=(1-cv)*128; bo=cl(b)*255
    return [[cv*S[r][0],cv*S[r][1],cv*S[r][2],cv*S[r][3]+t+bo] for r in range(3)]

def color_adjust(b,c,s):
    """eq is GPL (missing on phone): colorchannelmixer for the 3x3, lutrgb for the offset."""
    if not (b or c or s): return []
    m=color_matrix(b,c,s); out=[]
    ident=[[1,0,0],[0,1,0],[0,0,1]]
    if any(abs(m[r][k]-ident[r][k])>1e-6 for r in range(3) for k in range(3)):
        names=['rr','rg','rb','gr','gg','gb','br','bg','bb']  # by name: positional order has alpha slots
        out.append('colorchannelmixer='+':'.join(f"{names[r*3+k]}={m[r][k]:.4f}" for r in range(3) for k in range(3)))
    if any(abs(m[r][3])>1e-6 for r in range(3)):
        chs=[f"'clip(val+{m[r][3]:.3f}*maxval/255,minval,maxval)'" for r in range(3)]
        out.append(f"lutrgb=r={chs[0]}:g={chs[1]}:b={chs[2]}")
    return out

def look_filters(look):
    out=[]
    names=['rr','rg','rb','gr','gg','gb','br','bg','bb']
    if look in LOOKS: out.append('colorchannelmixer='+':'.join(f"{n}={x:.4f}" for n,x in zip(names,LOOKS[look])))
    if look=='vignette': out.append('vignette')
    return out

def boundary(clips, i):
    """Return (kind, ms, xfade) for the boundary after clip i. kind in cut|fade|dissolve."""
    if i>=len(clips)-1: return ('cut',0,'fade')
    a=dur(clips[i]); b=dur(clips[i+1])
    k=clips[i].get('transition','cut')
    if k in XFADE:
        t=min(MAX_T,a//2,b//2); return ('dissolve',t,XFADE[k]) if t>=100 else ('cut',0,'fade')
    if k=='fade':
        t=min(FADE_T,a//2,b//2); return ('fade',t,'fade') if t>=50 else ('cut',0,'fade')
    return ('cut',0,'fade')

def build_export(clips, overlays, music, aspect, short, out, encoder, fonts, textfiles, music_path=None, fps=FPS, duck=False):
    W,H=dims(aspect,short); n=len(clips); inputs=[]
    durs=[dur(c) for c in clips]
    for c,d in zip(clips,durs):
        if c['photo']: inputs += ['-loop','1','-framerate',str(fps),'-t',sec(d),'-i',c['path']]
        else: inputs += ['-i',c['path']]
    if music: inputs += ['-i',music['path']]
    bounds=[boundary(clips,i) for i in range(n)]
    f=[]
    for i,c in enumerate(clips):
        d=durs[i]; ch=[]; sp=speed_of(c)
        if not c['photo']:
            pts='setpts=PTS-STARTPTS' if sp==1.0 else f"setpts=(PTS-STARTPTS)/{sp:.3f}"
            ch.append(f"trim=start={sec(c['start'])}:end={sec(c['end'])},{pts}")
        ch += rotate_flip(c)
        ch.append(f"fps={fps}")
        if not c['photo']:  # exactly d long (mirrors export_command_builder, 2026-11-18)
            ch += [f"tpad=stop_mode=clone:stop_duration={sec(d)}", f"trim=end={sec(d)}"]
        head=f"[{i}:v]"
        fit=c.get('fit','fit')
        if fit=='fill':
            ch += [f"scale={W}:{H}:force_original_aspect_ratio=increase",f"crop={W}:{H}","setsar=1"]
        elif fit=='blur':
            ch.append(f"split[bg{i}][fg{i}]")
            f.append(head+",".join(ch))
            bw,bh=even(W/4),even(H/4)  # boxblur is GPL (missing on phone): gblur a quarter-size copy
            f.append(f"[bg{i}]scale={bw}:{bh}:force_original_aspect_ratio=increase,crop={bw}:{bh},gblur=sigma=6,scale={W}:{H}[bb{i}]")
            f.append(f"[fg{i}]scale={W}:{H}:force_original_aspect_ratio=decrease[ff{i}]")
            head=f"[bb{i}][ff{i}]"; ch=["overlay=(W-w)/2:(H-h)/2","setsar=1"]
        else:
            ch += [f"scale={W}:{H}:force_original_aspect_ratio=decrease",
                   f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=black","setsar=1"]
        b,ct,s=c.get('brightness',0),c.get('contrast',0),c.get('saturation',0)
        ch += color_adjust(b,ct,s)
        ch += look_filters(c.get('look'))
        ch.append("format=yuv420p")
        inb=bounds[i-1] if i>0 else ('cut',0,'fade'); outb=bounds[i]
        if inb[0]=='fade': ch.append(f"fade=t=in:st=0:d={sec(inb[1])}")
        if outb[0]=='fade': ch.append(f"fade=t=out:st={sec(d-outb[1])}:d={sec(outb[1])}")
        ch.append("settb=AVTB")
        f.append(head+",".join(ch)+f"[v{i}]")
        # audio
        if c.get('has_audio') and not c['photo']:
            vol=0 if c.get('muted') else c.get('volume',1.0)
            a=[f"atrim=start={sec(c['start'])}:end={sec(c['end'])}","asetpts=PTS-STARTPTS"]+atempo_chain(sp)+[
               f"aresample={AR}","aformat=sample_fmts=fltp:channel_layouts=stereo",f"volume={vol:.3f}",
               "apad",f"atrim=0:{sec(d)}","asetpts=PTS-STARTPTS"]  # exactly the clip's length (2026-11-18)
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
        kind,t,xf=bounds[i-1]
        if kind=='dissolve':
            f.append(f"[{cv}][v{i}]xfade=transition={xf}:duration={sec(t)}:offset={sec(D-t)},settb=AVTB,setpts=PTS-STARTPTS[x{i}]")
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
        if e<=s or not o['content'].strip() or o['id'] not in textfiles: continue
        fs=max(8,min(400,round(o['size']*W/REF_W))); font=fonts.get(o.get('font','Default'),fonts['Default'])
        style=''
        if o.get('outline',0)>0:
            bw=max(1,min(40,round(o['outline']*W/REF_W)))
            style+=f"borderw={bw}:bordercolor={color(o.get('outline_color',0xFF000000))}:"
        elif o.get('bold'):
            bw=max(1,min(6,round(fs*0.04)))
            style+=f"borderw={bw}:bordercolor={color(o['color'])}:"
        if o.get('box'):
            bb=max(2,min(60,round(6*W/REF_W)))
            style+=f"box=1:boxcolor={color(o.get('box_color',0x99000000))}:boxborderw={bb}:"
        nx=f"t{k}"
        f.append(f"[{cv}]drawtext=fontfile='{esc_path(font)}':textfile='{esc_path(textfiles[o['id']])}':expansion=none:"
                 f"fontsize={fs}:fontcolor={color(o['color'])}:{style}shadowcolor=black@0.6:shadowx=2:shadowy=2:"
                 f"x={o['x']:.4f}*w-text_w/2:y={o['y']:.4f}*h-text_h/2:enable='between(t,{sec(s)},{sec(e)})'[{nx}]")
        cv=nx; k+=1
    ao=ca
    if music:
        mi=n; ms=music['start']; me=music['end']; off=remap(music['offset']); md=me-ms
        fades=[]
        fi=music.get('fade_in',0); fo=music.get('fade_out',0)
        if fi>0: fades.append(f"afade=t=in:st=0:d={sec(fi)}")
        if fo>0: fades.append(f"afade=t=out:st={sec(max(0,min(md,md-fo)))}:d={sec(fo)}")
        f.append(f"[{mi}:a]atrim=start={sec(ms)}:end={sec(me)},asetpts=PTS-STARTPTS,aresample={AR},"
                 f"aformat=sample_fmts=fltp:channel_layouts=stereo,volume={music['volume']:.3f}"
                 +(','+','.join(fades) if fades else '')+f",adelay={off}:all=1[mus]")
        cb,mb=ca,'mus'
        if duck:
            f.append(f"[{ca}]asplit=2[dsc][dmix]")
            f.append("[mus][dsc]sidechaincompress=threshold=0.05:ratio=8[duck]")
            cb,mb='dmix','duck'
        f.append(f"[{cb}][{mb}]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.97[aout]")
        ao='aout'
    args=['-y']+inputs+['-filter_complex',';'.join(f),'-map',f'[{cv}]','-map',f'[{ao}]']+encoder+[
        '-pix_fmt','yuv420p','-r',str(fps),'-c:a','aac','-b:a','192k','-ar',str(AR),'-movflags','+faststart',out]
    return args,D,(W,H)
