from math import sin, cos, pi

class Ray:
    def __init__(self, value):
        x, y, z = self.value
        self.x = x
        self.y = y
        self.z = z

    def toArray(self):
        return (int(x), int(y), int(z))

    def rotX(self, angle):
        angle = angle * pi / 180
        return Ray(self.x, 
                   self.y * cos(angle) - self.z * sin(angle),
                   self.y * sin(angle) + self.z * cos(angle))

    def rotY(self, angle):
        angle = angle * pi / 180
        return Ray(self.x * cos(angle) + self.z * sin(angle),
                   self.y,
                   -self.x * sin(angle) + self.z * cos(angle))

    def rotZ(self, angle):
        angle = angle * pi / 180
        return Ray(self.x * cos(angle) - self.y * sin(angle),
                   self.x * sin(angle) + self.y * cos(angle),
                   self.z)
