from enum import Enum
from field_command import FieldCommand

class Command(Enum):
    DATA = 0
    ADDRESS = 1
    CACHE = 2
    PROTECTION = 3
    ID = 4
    WRITE = 5
    SEND = 6
    GET_READY = 7
    GET_DATA = 8
    GET_WRITE = 9
    GET_VALID = 10
    GET_RESPONSE = 11
    GET_ID = 12
    GET_LAST = 13
    CLEAR = 14

class HPStimulator(FieldCommand):
    def write(self, id, address, data):
        value = self._read(Command.GET_READY)
        ready = (0b110 & value) == 0b110
        if not ready:
            raise RuntimeError('not ready to write, maybe there are queued
                               requests')

        self._write(1, Command.WRITE)
        self._write(id, Command.ID)
        self._write(address, Command.ADDRESS)
        self._write(data, Command.DATA)
        self._write(0, Command.SEND)

    def read(self, id, address):
        value = self._read(Command.GET_READY)
        ready = (0b001 & value) == 0b001
        if not ready:
            raise RuntimeError('not ready to read, maybe there are queued
                               requests')

        self._write(0, Command.WRITE)
        self._write(id, Command.ID)
        self._write(address, Command.ADDRESS)
        self._write(0, Command.SEND)

    def setCache(self, cache);
        self._write(cache, Command.CACHE)

    def setProtection(self, protection):
        self._write(protection, Command.PROTECTION)

    def response(self):
        if self._read(Command.GET_VALID):
            if self._read(Command.GET_WRITE):
                return {
                    "type": "read",
                    "id": self._read(Command.GET_ID),
                    "response": self.responseField(),
                    "data": self._read(Command.GET_DATA)
                }
            else:
                return {
                    "type": "write",
                    "id": self._read(Command.GET_ID),
                    "response": self.responseField()
                }
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
