from enum import Enum

class MasterCommand(Enum):
    NONE = 0
    ADDRESS_LOWER = 1
    ADDRESS_UPPER = 2
    DATA = 3
    MASTER_ID = 4
    WRITE = 5
    TRY_SEND = 6
    READ_DATA = 7
    READ_MASTER_ID = 8
    TRY_TAKE = 9

FIELD_MASK = 0xFFFFFF

class MemoryMaster:
    def __init__(self, port, mID=0):
        self.port = port
        self.mID = mID
    
    def read(self, address):
        self.send(address, 0, False)
        rx = self.recieve()
        if (rx is None):
            raise Exception(f"read to {address} timed out")
        return rx

    def write(self, address, data):
        self.send(address, data, True)

    def recieve(self):
        return self.recieveAs(self.mID)

    def recieveAs(self, mID):
        self._write(0, MasterCommand.READ_MASTER_ID)
        if (self._read() != mID):
            return None

        self._write(0, MasterCommand.READ_DATA)
        data = self._read() & 0xFFFFFF
        self._write(0, MasterCommand.TRY_TAKE)
        if (self.read() == 0):
            return None
        
        self._write(0, MasterCommand.NONE)
        return data

    def send(self, address, data, write):
        self.sendAs(address, data, write, self.mID)

    def sendAs(self, address, data, write, mID):
        self._set_address(address)
        self._set_data(data)
        self._set_write(write)
        self._set_master_ID(mID)
        self._write(0, MasterCommand.TRY_SEND)

        if (self.port.read() == 0):
            raise Exception(f"send to {address} timed out")

        self._write(0, MasterCommand.NONE)

    def _set_write(self, write):
        value = 1 if write else 0
        self._write(value, MasterCommand.WRITE)

    def _set_master_ID(self, mID):
        self._write(mID, MasterCommand.MASTER_ID)

    def _set_data(self, data):
        self._write(data, MasterCommand.DATA)

    def _set_address(self, address):
        lower = address & FIELD_MASK
        upper = (address >> 24) & 0xFF;

        self._write(lower, MasterCommand.ADDRESS_LOWER)
        self._write(upper, MasterCommand.ADDRESS_UPPER)

    def _read(self):
        return self.port.read()

    def _write(self, field, command):
        value = (command.value << 24) + (field & FIELD_MASK)

        self.port.write(value, 0xFFFFFFFF)

class SlaveCommands(Enum):
    NONE = 0
    DATA = 1
    MASTER_ID = 2
    TRY_SEND = 3
    READ_ADDRESS = 4
    READ_DATA = 5
    READ_MASTER_ID = 6
    READ_WRITE = 7
    TRY_TAKE = 8

class MemorySlave:
    def __init__(self, port, addresses=(0,0xFFFFFFFF+1)):
        self.port = port
        self.lower = addresses[0]
        self.upper = addresses[1]
    
    def take(self):
        self._write(0, SlaveCommand.READ_ADDRESS)
        address = self._read()

        if address < self.lower or address >= self.upper:
            return None

        self._write(0, SlaveCommand.READ_WRITE)
        write = self._read() == 1
        
        self._write(0, SlaveCommand.READ_DATA)
        data = self._read() & 0xFFFFFF

        self._write(0, SlaveCommand.READ_MASTER_ID)
        mID = self._read() & 0xFF

        self._write(0, SlaveCommand.TRY_TAKE)
        if (self._read() == 0):
            self._write(0, SlaveCommand.NONE)
            return None
    
        self._write(0, SlaveCommand.NONE)

        return (address, data, write, mID)

    def _respond(data, mID):
        self._set_data(data)
        self._set_master_ID(mID)
        self._write(0, SlaveCommand.TRY_SEND)

        if (self._read() == 0):
            self._write(0, SlaveCommand.NONE)
            raise Exception(f"response to {mID} timed out")

        self._write(0, SlaveCommand.NONE)

    def _set_master_ID(self, mID):
        self._write(mID, SlaveCommand.MASTER_ID)

    def _set_data(self, data):
        self._write(data, SlaveCommand.DATA)

    def _read(self):
        return self.port.read()

    def _write(self, field, command):
        value = (command.value << 24) + (field & FIELD_MASK)

        self.port.write(value, 0xFFFFFFFF)

