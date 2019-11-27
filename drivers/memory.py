from enum import Enum
import numpy as np

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
        if (self._read() == 0):
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

class SlaveCommand(Enum):
    NONE = 0
    DATA = 1
    MASTER_ID = 2
    TRY_SEND = 3
    READ_ADDRESS = 4
    READ_DATA = 5
    READ_MASTER_ID = 6
    READ_WRITE = 7
    TRY_TAKE = 8

class MemoryBankController:
    def __init__(self, port):
        self.port = port
        self.slaves = []

    def attach(self, slave):
        self.slaves.append(slave)

    def step(self):
        result = self.port.take()

        if result is None:
            return

        for slave in self.slaves:
            slave.process(self.port, result)

class MemoryBank:
    def __init__(self, address, size):
        self.address = address
        self.size = size
        self.memory = np.zeros(size, dtype="int32")

    def read(self, i):
        return int(self.memory[i])

    def write(self, i, value):
        self.memory[i] = value

    def loadFile(self, filename):
        i = 0
        with open(filename, "r") as f:
            for line in f.readlines():
                line = line.strip()
                if line.startswith("#") or line == "":
                   continue

                line = line.replace("_", "")
                
                self.memory[i] = int(line, 0)
                i += 1

                if i >= self.size:
                    break

    def process(self, port, result):
        address, data, write, mID = result

        raddr = address - self.address
        if not (0 <= raddr < self.size):
            return False

        if write:
            self.write(raddr, data)
        else:
            port.respond(self.read(raddr), mID)

        return True

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
        write = self._read() != 0
        
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

    def respond(self, data, mID):
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

