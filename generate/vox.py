import sys
sys.path.append('/Users/huntingt/Documents/6.111/py-vox-io')

from pyvox.parser import VoxParser
from octree import Octree

m = VoxParser(sys.argv[1]).parse();

voxels = m.models[0].voxels

oc = Octree(32)

for voxel in voxels:
    oc.set(voxel.y, voxel.z, voxel.x, voxel.c)

# print palette
if False:
    output = "0x000000\n"
    for color in m.palette:
        output += f"0x{color.b:0{2}x}{color.g:0{2}x}{color.r:0{2}x}\n"
    print(output)

if True:
    print(oc.toOC())
