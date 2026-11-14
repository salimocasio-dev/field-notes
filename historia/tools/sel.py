# selected frames, big: python3 sel.py <dir> <out.png> <n1,n2,...> [W] [cols]
import sys,glob
from PIL import Image,ImageDraw
d,out,ns=sys.argv[1],sys.argv[2],[int(x) for x in sys.argv[3].split(",")]
W=int(sys.argv[4]) if len(sys.argv)>4 else 500; cols=int(sys.argv[5]) if len(sys.argv)>5 else 3
import re,os
fs=sorted(glob.glob(d+"/*.png"),key=lambda p:int(re.match(r"\d+",os.path.basename(p)).group()) if re.match(r"\d+",os.path.basename(p)) else 0); ims=[Image.open(fs[n-1]).convert("RGB") for n in ns]; ims=[i.resize((W,int(i.height*W/i.width)),Image.NEAREST) for i in ims]; H=ims[0].height
rows=(len(ims)+cols-1)//cols; sh=Image.new("RGB",(cols*W,rows*H),(20,20,20)); dr=ImageDraw.Draw(sh)
for i,im in enumerate(ims):
    x,y=(i%cols)*W,(i//cols)*H; sh.paste(im,(x,y)); dr.rectangle([x,y,x+34,y+18],fill=(0,0,0)); dr.text((x+4,y+3),str(ns[i]),fill=(255,255,0))
sh.save(out)
