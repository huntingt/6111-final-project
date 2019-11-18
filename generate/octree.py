# generate a full octree then optimize away similar nodes
class Octree:
    def __init__(self, size, value=0):
        self.children = [value] * 8;
        self.size = size

    def get(self, x, y, z):
        hs = self.size//2
        index = (x >= hs) + 2*(y >= hs) + 4*(z >= hs)
        element = self.children[index]

        if isinstance(element, int):
            return element
        else:
            return element.get(x % hs, y % hs, z % hs)

    def set(self, x, y, z, value):
        hs = self.size//2
        index = (x >= hs) + 2*(y >= hs) + 4*(z >= hs)
        element = self.children[index]

        if hs == 1:
            self.children[index] = value
        elif isinstance(element, int):
            self.children[index] = Octree(hs, element)
            self.children[index].set(x % hs, y % hs, z % hs, value)
        else:
            return element.set(x % hs, y % hs, z % hs, value)
    
    def toOC(self):
        return self._toOC()[1]

    def _toOC(self, index=0):
        output = f"# node {index}\n"
        end = ""
        for child in self.children:
            if isinstance(child, int):
                output += f"0xffff_{child:0{2}x}\n"
            else:
                output += f"{index + 1}\n"
                index, subout = child._toOC(index + 1)
                end += subout
        return index, output + end

