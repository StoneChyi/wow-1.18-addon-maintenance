// Offline orthographic scenery rasterizer. No client hooks, DLL installation or
// window creation. Input/output jobs and extracted textures stay in staging.
using System;
using System.IO;
using System.Collections.Generic;

public static class TurtleTerrainRaster {
    sealed class Tex { public int W,H; public byte[] P; }
    static Dictionary<string,Tex> Cache = new Dictionary<string,Tex>();
    static Tex Texture(string path) {
        Tex t;
        if(Cache.TryGetValue(path,out t)) return t;
        using(var r=new BinaryReader(File.OpenRead(path))) {
            t=new Tex();t.W=r.ReadInt32();t.H=r.ReadInt32();
            if(t.W<1 || t.H<1 || t.W>4096 || t.H>4096) throw new Exception("Invalid texture dimensions");
            t.P=r.ReadBytes(t.W*t.H*4);
            if(t.P.Length!=t.W*t.H*4) throw new Exception("Truncated texture");
        }
        if(Cache.Count>256) Cache.Clear();Cache[path]=t;return t;
    }
    static float Edge(float ax,float ay,float bx,float by,float x,float y) {
        return (x-ax)*(by-ay)-(y-ay)*(bx-ax);
    }
    public static string Render(string path) {
        using(var r=new BinaryReader(File.OpenRead(path))) {
            if(r.ReadInt32()!=0x37524d54) throw new Exception("Invalid render job");
            int w=r.ReadInt32(),h=r.ReadInt32();
            if(w<1 || h<1 || (long)w*h>100000000) throw new Exception("Invalid canvas");
            string output=r.ReadString();byte[] color=r.ReadBytes(w*h*4);
            if(color.Length!=w*h*4) throw new Exception("Truncated base");
            float[] depth=new float[w*h];byte[] coverage=new byte[w*h];
            for(int i=0;i<depth.Length;i++) depth[i]=r.ReadSingle();
            int meshes=r.ReadInt32();long triangles=0,drawn=0;
            for(int mesh=0;mesh<meshes;mesh++) {
                Tex tex=Texture(r.ReadString());int nv=r.ReadInt32(),ni=r.ReadInt32();
                if(nv<0 || nv>2000000 || ni<0 || ni>12000000 || ni%3!=0) throw new Exception("Invalid mesh");
                float[] v=new float[nv*6];for(int i=0;i<v.Length;i++) v[i]=r.ReadSingle();
                int[] indices=new int[ni];for(int i=0;i<ni;i++){indices[i]=r.ReadInt32();if(indices[i]<0 || indices[i]>=nv)throw new Exception("Bad index");}
                for(int t=0;t<ni;t+=3) {
                    triangles++;int a=indices[t]*6,b=indices[t+1]*6,c=indices[t+2]*6;
                    float area=Edge(v[a],v[a+1],v[b],v[b+1],v[c],v[c+1]);
                    if(Math.Abs(area)<.00001f) continue;
                    int l=Math.Max(0,(int)Math.Floor(Math.Min(v[a],Math.Min(v[b],v[c]))));
                    int right=Math.Min(w-1,(int)Math.Ceiling(Math.Max(v[a],Math.Max(v[b],v[c]))));
                    int top=Math.Max(0,(int)Math.Floor(Math.Min(v[a+1],Math.Min(v[b+1],v[c+1]))));
                    int bot=Math.Min(h-1,(int)Math.Ceiling(Math.Max(v[a+1],Math.Max(v[b+1],v[c+1]))));
                    for(int y=top;y<=bot;y++) for(int x=l;x<=right;x++) {
                        float p=Edge(v[b],v[b+1],v[c],v[c+1],x+.5f,y+.5f)/area;
                        float q=Edge(v[c],v[c+1],v[a],v[a+1],x+.5f,y+.5f)/area;
                        float z=1-p-q;if(p<-.00001f || q<-.00001f || z<-.00001f) continue;
                        float height=p*v[a+2]+q*v[b+2]+z*v[c+2];int at=y*w+x;
                        if(height<depth[at]-.05f) continue;
                        float u=(p*v[a+3]+q*v[b+3]+z*v[c+3])*tex.W;
                        float vv=(p*v[a+4]+q*v[b+4]+z*v[c+4])*tex.H;
                        int ix=(int)Math.Floor(u),iy=(int)Math.Floor(vv);float fx=u-ix,fy=vv-iy;
                        int xx=((ix%tex.W)+tex.W)%tex.W, yy=((iy%tex.H)+tex.H)%tex.H;
                        int p0=(yy*tex.W+xx)*4,p1=(yy*tex.W+(xx+1)%tex.W)*4;
                        int p2=(((yy+1)%tex.H)*tex.W+xx)*4,p3=(((yy+1)%tex.H)*tex.W+(xx+1)%tex.W)*4;
                        float aa=(tex.P[p0+3]*(1-fx)+tex.P[p1+3]*fx)*(1-fy)+(tex.P[p2+3]*(1-fx)+tex.P[p3+3]*fx)*fy;
                        if(aa<127)continue;
                        float shade=p*v[a+5]+q*v[b+5]+z*v[c+5];
                        for(int channel=0;channel<3;channel++) {
                            float value=((tex.P[p0+channel]*(1-fx)+tex.P[p1+channel]*fx)*(1-fy)+(tex.P[p2+channel]*(1-fx)+tex.P[p3+channel]*fx)*fy)*shade;
                            color[at*4+channel]=(byte)Math.Max(0,Math.Min(255,value));
                        }
                        color[at*4+3]=255;depth[at]=height;coverage[at]=255;drawn++;
                    }
                }
            }
            File.WriteAllBytes(output,color);
            File.WriteAllBytes(Path.ChangeExtension(output,".coverage"),coverage);
            return "triangles="+triangles+" fragments="+drawn+" output="+Path.GetFileName(output);
        }
    }
}
