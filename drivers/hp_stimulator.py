from enum import Enum
from field_command import FieldCommand

class Command(Enum):
    DATA = 0
    ADDRESS_LOWER = 1
    ADDRESS_UPPER = 2
    CACHE = 3
    PROTECTION = 4
    ID = 5
    WRITE = 6
    BURST = 7
    SEND = 8
    GET_READY = 9
    GET_DATA = 10
    GET_WRITE = 11
    GET_VALID = 12
    GET_RESPONSE = 13
    GET_ID = 14
    GET_LAST = 15
    CLEAR = 16

class Burst(Enum):
    FIXED = 0
    INCR = 1
    WRAP = 2

class HPStimulator(FieldCommand):
    def write(self, id, address, data):
        value = self._read(Command.GET_READY)
        ready = (0b110 & value) == 0b110
        if not ready:
            raise RuntimeError('not ready to write, maybe there are queued\
                               requests')

        self._write(Command.WRITE, 1)
        self._write(Command.ID, id)
        self.setAddress(address)
        self._write(Command.DATA, data >> 8)
        self._write(Command.SEND)

    def read(self, id, address):
        value = self._read(Command.GET_READY)
        ready = (0b001 & value) == 0b001
        if not ready:
            raise RuntimeError('not ready to read, maybe there are queued\
                               requests')

        self._write(Command.WRITE, 0)
        self._write(Command.ID, id)
        self.setAddress(address)
        self._write(Command.SEND)

    def setAddress(self, address):
        self._write(Command.ADDRESS_LOWER, address & 0xffffff)
        self._write(Command.ADDRESS_UPPER, (address >> 24) & 0xff)

    def setCache(self, cache):
        self._write(Command.CACHE, cache)

    def setBurst(self, burst):
        self._write(Command.BURST, burst.value)

    def setProtection(self, protection):
        self._write(Command.PROTECTION, protection)

    def response(self):
        if self._read(Command.GET_VALID):
            output = {
                "id": self._read(Command.GET_ID),
                "response": self.responseField(),
            }

            if self._read(Command.GET_WRITE):
                output["type"] = "write"
            else:
                output["type"] = "read"
                output["data"] = self._read(Command.GET_DATA)
            
            self._write(Command.CLEAR)
            return output
        else:
            return None

    def responseField(self):
        value = self._read(Command.GET_RESPONSE)

        status = {
            0: "normal okay",
            1: "exclusive okay",
            2: "slave error",
            3: "decode error"
        }

        cache = "must write back" if value & 0b100 else "okay"
        shared = "maybe shared" if value & 0b1000 else "unique"

        return f"{status[value & 0b11]}, {cache}, {shared}"
