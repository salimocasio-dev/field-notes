# all frames of a folder as numbered sheets: python3 hojas.py <dir> <outprefix> [per] [cols] [W]
import sys,glob
from PIL import Image,ImageDraw
d,out=sys.argv[1],sys.argv[2]; per=int(sys.argv[3]) if len(sys.argv)>3 else 20; cols=int(sys.argv[4]) if len(sys.argv)>4 else 4; W=int(sys.argv[5]) if len(sys.argv)>5 else 330
import re,os
fs=sorted(glob.glob(d+"/*.png"),key=lambda p:int(re.match(r"\d+",os.path.basename(p)).group()) if re.match(r"\d+",os.path.basename(p)) else 0)
for k in range(0,len(fs),per):
    ims=[Image.open(f).convert("RGB") for f in fs[k:k+per]]; ims=[i.resize((W,int(i.height*W/i.width))) for i in ims]; H=max(i.height for i in ims)
    rows=(len(ims)+cols-1)//cols; sh=Image.new("RGB",(cols*W,rows*H),(20,20,20)); dr=ImageDraw.Draw(sh)
    for i,im in enumerate(ims):
        x,y=(i%cols)*W,(i//cols)*H; sh.paste(im,(x,y)); dr.rectangle([x,y,x+34,y+18],fill=(0,0,0)); dr.text((x+4,y+3),str(k+i+1),fill=(255,255,0))
    o=f"{out}_{k//per+1}.png"; sh.save(o); print(o)
