"""Renders a synthetic project through the export filter graph with a REAL ffmpeg (needs ffmpeg + DejaVu fonts on PATH)
and checks duration/size/streams. Usage: python3 tools/verify_export_graph.py
The Dart builder (lib/export/export_command_builder.dart) is a port of graph_prototype.py - keep them in step."""
import subprocess,json,os,sys
from graph_prototype import *
os.makedirs('_work',exist_ok=True); os.chdir('_work')
def sh(c): subprocess.run(c,shell=True,check=True,capture_output=True)
sh("ffmpeg -y -f lavfi -i testsrc2=s=1280x720:r=24:d=5 -f lavfi -i sine=f=440:d=5 -shortest -c:v libx264 -c:a aac A.mp4")
sh("ffmpeg -y -f lavfi -i testsrc=s=640x480:r=30:d=4 -c:v libx264 B.mp4")   # no audio, different aspect
sh("ffmpeg -y -f lavfi -i color=c=orange:s=800x600 -frames:v 1 P.png")
sh("ffmpeg -y -f lavfi -i sine=f=220:d=12 M.mp3")
D='/usr/share/fonts/truetype/dejavu/'
fonts={'Default':D+'DejaVuSans.ttf','Serif':D+'DejaVuSerif.ttf'}
open('t1.txt','w').write("Hello: 100% 'quoted'\nsecond line"); open('t2.txt','w').write("Later text")
clips=[dict(path='A.mp4',photo=False,start=1000,end=4000,transition='dissolve',has_audio=True,brightness=.1,contrast=.2,saturation=-.3,volume=.8),
       dict(path='B.mp4',photo=False,start=0,end=3000,transition='fade',has_audio=False),
       dict(path='P.png',photo=True,start=0,end=2000,transition='cut'),
       dict(path='A.mp4',photo=False,start=0,end=2000,has_audio=True,muted=True)]
ov=[dict(id='1',content='x',start=500,end=2500,color=0xFFFFEB3B,size=24,x=.5,y=.2),
    dict(id='2',content='x',start=7000,end=9000,color=0xFFFFFFFF,size=30,x=.5,y=.8,font='Serif')]
tf={'1':'t1.txt','2':'t2.txt'}
music=dict(path='M.mp3',start=0,end=12000,offset=500,volume=.5)
args,Dm,(W,H)=build_export(clips,ov,music,9/16,720,'out.mp4',['-c:v','libx264','-preset','veryfast','-b:v','5M'],fonts,tf)
open('cmd.txt','w').write(' '.join(args))
r=subprocess.run(['ffmpeg']+args,capture_output=True,text=True)
if r.returncode: print(r.stderr[-2500:]); sys.exit(1)
p=json.loads(subprocess.run("ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name,width,height,r_frame_rate -of json out.mp4",shell=True,capture_output=True,text=True).stdout)
print('expected ms',Dm,'size',W,H); print(json.dumps(p))
dur=float(p['format']['duration'])*1000
vs=[x for x in p['streams'] if x['codec_type']=='video'][0]
assert abs(dur-Dm)<80, ('duration mismatch',dur,Dm)
assert (vs['width'],vs['height'])==(W,H)
assert {x['codec_type'] for x in p['streams']}=={'video','audio'}
print('OK: export graph renders; duration, size and streams match')
for t in (0.5,3.2,5.8,8.0): sh(f"ffmpeg -y -ss {t} -i out.mp4 -frames:v 1 f{t}.png")
