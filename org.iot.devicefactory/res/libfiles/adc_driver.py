from machine import ADC, Pin
from collections import namedtuple

class ADCDriver:

    def __init__(self, tuple, *pins: int):
        self.adcs = [ADC(Pin(pin, Pin.IN)) for pin in pins]
        for adc in self.adcs:
            adc.atten(ADC.ATTN_6DB)
        self.tuple = tuple

    def sample(self):
        return self.tuple(*[adc.read() for adc in self.adcs])
