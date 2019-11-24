from enum import Enum

class Field(Enum):
    CONFIG=0
    MATERIAL=1
    TREE=2
    FRAME=3
    QX=4
    QY=5
    QZ=6
    VX=7
    VY=8
    VZ=9
    XX=10
    XY=11
    XZ=12
    YX=13
    YY=14
    YZ=15
    WIDTH=16
    HEIGHT=17

class ConfigField(Enum):
    START=0
    READY=1
    BUSY=2
    FLUSH=3
    RESET=4
    NORMALIZE=5

class RayTracer:
    def __init__(self, port, address):
        self.port = port
        self.address = address

    def start(self):
        self.setConfig(ConfigField.START, True)

    def busy(self):
        return self.getConfig(ConfigField.BUSY)

    def ready(self):
        return self.getConfig(ConfigField.READY)

    def setConfig(self, field, value):
        current = self.read(Field.CONFIG)
        mask = 1 << field.value
        if value:
            self.write(Field.CONFIG, current | mask)
        else:
            self.write(Field.CONFIG, current & ~mask)

    def getConfig(self, field):
        current = self.read(Field.CONFIG)
        mask = 1 << field.value
        return (current & mask) == 1

    def setCamera(self, q, v, x, y):
        qx, qy, qz = q
        self.write(Field.QX, qx)
        self.write(Field.QY, qy)
        self.write(Field.QZ, qz)

        vx, vy, vz = v
        self.write(Field.VX, vx)
        self.write(Field.VY, vy)
        self.write(Field.VZ, vz)

        xx, xy, xz = x
        self.write(Field.XX, xx)
        self.write(Field.XY, xy)
        self.write(Field.XZ, xz)
        
        yx, yy, yz = y
        self.write(Field.YY, yx)
        self.write(Field.YY, yy)
        self.write(Field.YY, yz)

    def setScene(self, materialAddress, treeAddress):
        self.write(Field.MATERIAL, materialAddress >> 8)
        self.write(Field.TREE, treeAddress >> 8)

    def setFrame(self, width, height, frameAddress):
        self.write(Field.WIDTH, width)
        self.write(Field.HEIGHT, height)
        self.write(Field.FRAME, frameAddress)

    def write(self, field, value):
        self.port.write(self.address + field.value, value)

    def read(self, field):
        return self.port.read(self.address + field.value)
