import sys
sys.path.append('/Users/huntingt/Documents/6.111/py-vox-io')

from pyvox.parser import VoxParser
from octree import Octree
from argparse import ArgumentParser

if __name__ == '__main__':
    parser = ArgumentParser("Parse a magica voxel file into an octree format")
    parser.add_argument('input', help="input octree filename")
    parser.add_argument('size', type=int, help="cells per octree side")
    parser.add_argument('-oc', help="output .oc file representing the tree")
    parser.add_argument('-mat', help="output .mat file representing the materials")
    args = parser.parse_args()
    
    m = VoxParser(args.input).parse(); 
    oc = Octree(args.size)

    for model in m.models:
        for voxel in model.voxels:
            oc.set(voxel.x, voxel.y, voxel.z, voxel.c)

    if args.oc:
        with open(args.oc, 'w') as f:
            f.write(oc.toOC())

    if args.mat:
        output = "0x000000\n"
        for color in m.palette:
            output += f"0x{color.b:0{2}x}{color.g:0{2}x}{color.r:0{2}x}\n"

        with open(args.mat, 'w') as f:
            f.write(output)
