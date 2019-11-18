import sys
sys.path.append('/Users/huntingt/Documents/6.111/py-vox-io')

from pyvox.parser import VoxParser
from octree import Octree

m = VoxParser(sys.argv[1]).parse();

voxels = m.models[0].voxels

oc = Octree(32)

for voxel in voxels:
    oc.set(voxel.y, voxel.z, voxel.x, voxel.c)

print(oc.toOC())
