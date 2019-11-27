class FieldCommand:
    """Base driver for field command type devices"""
    def __init__(self, channel):
        """Makes a new peripherial driver using gpio channel 'channel'"""
        self.channel = channel

    def _write(self, field, command):
        value = (field & 0xFFFFFF) | (command.value << 24)
        self.channel.write(value, 0xFFFFFFFF)

    def _read(self, command, field = 0):
        self._write(field, command)
        return self.channel.read()
