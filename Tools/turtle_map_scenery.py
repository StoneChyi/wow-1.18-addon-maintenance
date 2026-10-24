"""Read-only static 1.12 scenery projection for map production, not game code.

Model records are validated against their own buffers. Original geometry/UVs and
placements are used; no inferred building, road or spawn is added. Animated bones,
particles, translucent effects and WMO-contained doodads are not simulated.
"""
import hashlib
import math
import re
import struct
import subprocess
from collections import Counter

import numpy as np
from PIL import Image
from build_turtle_map_terrain import chunks,STEP
from build_turtle_seamless_map import ROOT,STAGING,decode_blp

CACHE=STAGING/'v7-hd-candidate/cache'


def array(data,offset,stride,dtype):
    if offset<0 or offset+8>len(data):raise ValueError('Array descriptor outside model')
    n,start=struct.unpack_from('<II',data,offset)
    if n>2000000 or start+n*stride>len(data):raise ValueError('Array outside model')
    return np.frombuffer(data[start:start+n*stride],dtype=dtype)


def cstring(data,offset):
    if offset<0 or offset>=len(data):raise ValueError('String outside model')
    end=data.find(b'\0',offset)
    if end<0:raise ValueError('Unterminated model string')
    return data[offset:end].decode('ascii')


def wmo_chunks(data,start=0):
    """Some installed exports append a non-chunk footer after valid arrays.

    Accept at most 128 footer bytes only after mandatory model chunks exist;
    truncating a required geometry array remains an error.
    """
    result={};off=start
    while off+8<=len(data):
        tag=data[off:off+4];size=struct.unpack_from('<I',data,off+4)[0]
        if off+8+size>len(data):
            root={b'DHOM',b'XTOM',b'TMOM',b'IGOM'}<=set(result)
            group={b'TVOM',b'IVOM',b'VTOM',b'RNOM'}<=set(result)
            if len(data)-off<=128 and (root or group) and not all(65<=v<=90 for v in tag):break
            raise ValueError('Truncated required WMO chunk')
        result[tag]=data[off+8:off+8+size];off+=8+size
    return result


def liquid_mesh(raw):
    """Validated legacy MLIQ grid; low-nibble 15 is a disabled liquid cell.

    Heights are absolute local Z, not offsets from the header's corner Z.
    Shared grid vertices let the depth buffer retain bridges above the water.
    """
    if len(raw)<30:raise ValueError('Truncated WMO liquid header')
    nx,ny,tx,ty,px,py,pz,material=struct.unpack_from('<4I3fH',raw)
    if nx!=tx+1 or ny!=ty+1 or nx<2 or ny<2 or nx*ny>1000000:raise ValueError('Invalid WMO liquid grid')
    end=30+nx*ny*8
    if len(raw)!=end+tx*ty:raise ValueError('Truncated WMO liquid arrays')
    heights=np.frombuffer(raw[30:end],dtype=np.dtype([('flow','<u4'),('height','<f4')]))['height']
    if not np.isfinite(heights).all():raise ValueError('Nonfinite WMO liquid height')
    x,y=np.meshgrid(np.arange(nx),np.arange(ny));spacing=STEP/128
    xyz=np.column_stack((px+x.ravel()*spacing,py+y.ravel()*spacing,heights)).astype('<f4')
    normal=np.tile([0,0,1],(nx*ny,1));uv=xyz[:,:2]/(spacing*8);indices=[]
    flags=np.frombuffer(raw[end:],dtype='u1').reshape(ty,tx)
    for y,x in zip(*np.nonzero((flags&15)!=15)):
        a=y*nx+x;indices.extend((a,a+1,a+nx,a+1,a+nx+1,a+nx))
    return xyz,normal,uv,np.asarray(indices,dtype='<u4'),material


def placement_matrix(rotation):
    a,b,c=np.radians(rotation)
    rx=np.array([[1,0,0],[0,np.cos(c),-np.sin(c)],[0,np.sin(c),np.cos(c)]])
    ry=np.array([[np.cos(a),0,np.sin(a)],[0,1,0],[-np.sin(a),0,np.cos(a)]])
    rz=np.array([[np.cos(b+math.pi),-np.sin(b+math.pi),0],[np.sin(b+math.pi),np.cos(b+math.pi),0],[0,0,1]])
    return np.array([[0,-1,0],[-1,0,0],[0,0,1]])@rz@ry@rx


def placements(data):
    d=dict(chunks(data));out=[]
    for kind,nametag,offsettag,tag,fmt in (('wmo',b'OMWM',b'DIWM',b'FDOM','<II12f4H'),('m2',b'XDMM',b'DIMM',b'FDDM','<II6fHH')):
        names=d.get(nametag,b'');offsets=list(struct.iter_unpack('<I',d.get(offsettag,b'')))
        for row in struct.iter_unpack(fmt,d.get(tag,b'')):
            if row[0]>=len(offsets):raise ValueError('Invalid ADT model name id')
            name=cstring(names,offsets[row[0]][0]).lower()
            if kind=='m2':name=name.rsplit('.',1)[0]+'.m2'
            out.append(dict(kind=kind,path=name,uid=row[1],position=[row[2],row[4],row[3]],rotation=list(row[5:8]),scale=row[8]/1024 if kind=='m2' else 1,raw=row))
    return out


class Scenery:
    def __init__(self,client,skip_foliage=False):
        self.client=client;self.models={};self.textures={};self.sources={};self.counts=Counter();self.errors={}
        self.skip_foliage=skip_foliage
        CACHE.mkdir(parents=True,exist_ok=True)

    def read(self,path):
        data,source=self.client.read(path)
        self.sources[path]=dict(source=source,sha256=hashlib.sha256(data).hexdigest())
        return data

    def texture(self,name,opaque=False):
        key=(name,opaque)
        if key not in self.textures:
            data=self.read(name);image=decode_blp(data).convert('RGBA')
            # Opaque materials can store unrelated masks in diffuse alpha.
            # The client ignores that alpha; treating it as cutout deletes floors.
            if opaque:image.putalpha(255)
            if max(image.size)>1024:image.thumbnail((1024,1024),Image.Resampling.LANCZOS)
            path=CACHE/(hashlib.sha256((name.lower()+str(opaque)).encode()).hexdigest()+'.tex')
            path.write_bytes(struct.pack('<II',*image.size)+image.tobytes());self.textures[key]=str(path)
        return self.textures[key]

    def model(self,kind,path):
        key=(kind,path)
        if key in self.models:return self.models[key]
        try:
            result=self.wmo(path) if kind=='wmo' else self.m2(path)
            self.counts[kind+'_models']+=1
        except (ValueError,KeyError,FileNotFoundError,struct.error) as error:
            self.errors[path]=str(error);result=[]
        self.models[key]=result
        return result

    def wmo(self,path):
        data=self.read(path);root=wmo_chunks(data);materials=[]
        for off in range(0,len(root[b'TMOM']),64):
            flags,shader,blend,texture=struct.unpack_from('<4I',root[b'TMOM'],off)
            name=cstring(root[b'XTOM'],texture)
            materials.append(self.texture(name,blend==0) if name and blend<=1 else None)
        groups=list(struct.iter_unpack('<I6fi',root[b'IGOM']));meshes=[]
        for index,group in enumerate(groups):
            raw=self.read(path[:-4]+f'_{index:03d}.wmo')
            if not raw:continue
            payload=wmo_chunks(raw)[b'PGOM'];parts=wmo_chunks(payload,68)
            # Stormwind canals are WMO liquids. Their bottom floor is not a
            # road. Keep the real grid height so bridges occlude the liquid.
            if b'QILM' in parts and path.lower().endswith('stormwind\\stormwind.wmo'):
                xyz,norm,water_uv,water_indices,_=liquid_mesh(parts[b'QILM'])
                if len(water_indices):
                    source=r'XTextures\river\lake_a.1.blp'
                    water=decode_blp(self.read(source)).convert('RGBA')
                    # The client applies a liquid shader; a static map uses the
                    # source wave alpha in a restrained river colour instead.
                    wave=np.asarray(water.getchannel('A'),dtype=float)/255
                    rgb=np.clip((.86+.24*wave[:,:,None])*np.array([38,91,99]),0,255).astype('uint8')
                    image=Image.fromarray(rgb).convert('RGBA');target=CACHE/('stormwind-water-'+hashlib.sha256(image.tobytes()).hexdigest()+'.tex')
                    if not target.exists():target.write_bytes(struct.pack('<II',*image.size)+image.tobytes())
                    meshes.append((xyz,norm,water_uv,water_indices,str(target)))
                    self.counts['stormwind_liquid_groups']+=1
                    self.counts['stormwind_liquid_triangles']+=len(water_indices)//3
            if not parts.get(b'TVOM') or not parts.get(b'IVOM'):continue
            positions=np.frombuffer(parts[b'TVOM'],dtype='<f4').reshape(-1,3)
            uv=np.frombuffer(parts[b'VTOM'],dtype='<f4').reshape(-1,2)
            normals=np.frombuffer(parts[b'RNOM'],dtype='<f4').reshape(-1,3)
            indices=np.frombuffer(parts[b'IVOM'],dtype='<u2')
            if len(uv)!=len(positions) or len(normals)!=len(positions) or len(indices)%3 or indices.max()>=len(positions):raise ValueError('Inconsistent WMO mesh arrays')
            used=False
            for off in range(0,len(parts.get(b'ABOM',b'')),24):
                start=struct.unpack_from('<I',parts[b'ABOM'],off+12)[0]
                count=struct.unpack_from('<H',parts[b'ABOM'],off+16)[0];material=parts[b'ABOM'][off+23]
                if material==255:continue
                if material>=len(materials) or start+count>len(indices) or count%3:raise ValueError('Invalid WMO batch')
                if materials[material] and count:
                    meshes.append((positions,normals,uv,indices[start:start+count],materials[material]));used=True
            if not used and not parts.get(b'ABOM'):
                info=np.frombuffer(parts[b'YPOM'],dtype='u1').reshape(-1,2)
                for material in np.unique(info[:,1]):
                    if material>=len(materials) or not materials[material]:continue
                    take=indices.reshape(-1,3)[info[:,1]==material].reshape(-1)
                    meshes.append((positions,normals,uv,take,materials[material]))
        return meshes

    def m2(self,path):
        data=self.read(path)
        if data[:4]!=b'MD20' or struct.unpack_from('<I',data,4)[0] not in (256,257):raise ValueError('Not a 1.12 embedded-skin model')
        dtype=np.dtype([('pos','<f4',3),('weights','u1',4),('bones','u1',4),('normal','<f4',3),('uv','<f4',2),('unused','<f4',2)])
        vertices=array(data,0x44,48,dtype);views=array(data,0x4c,44,np.dtype(('u1',44)))
        if not len(views):return []
        view=np.asarray(views[0]).tobytes()
        # View descriptors point into MD20, not into the 44-byte view itself.
        def values(offset,stride,dtype):
            n,start=struct.unpack_from('<II',view,offset)
            if start+n*stride>len(data):raise ValueError('Embedded skin outside model')
            return np.frombuffer(data[start:start+n*stride],dtype=dtype)
        lookup=values(0,2,'<u2');triangles=values(8,2,'<u2')
        if len(triangles)%3 or (len(triangles) and triangles.max()>=len(lookup)):raise ValueError('Invalid M2 skin indices')
        indices=lookup[triangles]
        if len(indices) and indices.max()>=len(vertices):raise ValueError('Invalid M2 vertices')
        texture_rows=array(data,0x5c,16,np.dtype(('<u4',4)));texture_names=[]
        for row in texture_rows:
            typ,flags,length,start=map(int,row)
            if length and start+length<=len(data) and typ==0:texture_names.append(cstring(data,start))
            else:texture_names.append(None)
        # Vanilla carries an extra array at 0x7c. Materials and texture lookup
        # are at 0x84 / 0x94, unlike a later-version or incomplete header map.
        textures=array(data,0x94,2,'<u2');materials=array(data,0x84,4,np.dtype(('<u2',2)))
        subs=values(24,32,np.dtype(('u1',32)));units=values(32,24,np.dtype(('<u2',12)))
        meshes=[];seen=set()
        for unit in units:
            sub,material,combo=int(unit[2]),int(unit[5]),int(unit[8])
            if (sub,combo) in seen:continue
            seen.add((sub,combo))
            if sub>=len(subs) or material>=len(materials) or combo>=len(textures):raise ValueError('Invalid M2 material reference')
            tid=int(textures[combo]);blend=int(materials[material][1])
            if tid>=len(texture_names) or not texture_names[tid] or blend>1:continue
            start,count=struct.unpack_from('<HH',np.asarray(subs[sub]).tobytes(),8)
            if start+count>len(indices) or count%3:raise ValueError('Invalid M2 submesh')
            meshes.append((vertices['pos'],vertices['normal'],vertices['uv'],indices[start:start+count],self.texture(texture_names[tid],blend==0)))
        return meshes

    def job(self,path,image,depth,objects,bounds):
        """Model vertices project into exactly the terrain's engine-coordinate box."""
        width,height=image.size;meshes=[];seen=set();left,top,right,bottom=bounds
        for obj in objects:
            key=(obj['kind'],obj['uid'])
            if key in seen:continue
            seen.add(key)
            if self.skip_foliage and obj['kind']=='m2' and re.search(r'tree|bush|fern|shrub|foliage|grass|flower|vine|branch',obj['path'],re.I):
                self.counts['canopy_instances_skipped']+=1;continue
            matrix=placement_matrix(obj['rotation'])*obj['scale'];position=np.asarray(obj['position'])
            for xyz,normals,uv,indices,texture in self.model(obj['kind'],obj['path']):
                world=xyz@matrix.T+position
                if world[:,0].max()<left or world[:,0].min()>right or world[:,1].max()<top or world[:,1].min()>bottom:continue
                normal=normals@matrix.T;normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),.001)
                light=np.clip(.74+.26*(normal@np.array([-.25,-.35,.90])),.55,1.05)
                vertices=np.column_stack(((world[:,0]-left)/(right-left)*width,(world[:,1]-top)/(bottom-top)*height,world[:,2],uv,light)).astype('<f4')
                meshes.append((vertices,indices.astype('<i4'),texture))
            self.counts[obj['kind']+'_instances']+=1
        def string(file,s):
            data=s.encode('utf8');n=len(data)
            while n>=128:file.write(bytes([(n&127)|128]));n>>=7
            file.write(bytes([n]));file.write(data)
        output=path.with_suffix('.rgba')
        with path.open('wb') as file:
            file.write(struct.pack('<III',0x37524d54,width,height));string(file,str(output))
            file.write(image.convert('RGBA').tobytes());file.write(np.asarray(depth,dtype='<f4').tobytes());file.write(struct.pack('<I',len(meshes)))
            for vertices,indices,texture in meshes:
                string(file,texture);file.write(struct.pack('<II',len(vertices),len(indices)));file.write(vertices.tobytes());file.write(indices.tobytes())
        return output


def rasterize(jobs):
    listing=CACHE/'jobs.txt';listing.write_text('\n'.join(str(p) for p in jobs),encoding='utf8')
    subprocess.run(['pwsh','-NoProfile','-File',str(ROOT/'Tools/render_turtle_terrain.ps1'),'-Jobs',str(listing)],check=True,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
