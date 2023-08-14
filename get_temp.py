#!/usr/bin/python3

from smbus2 import SMBus

def word_To_LSB_MSB(word):
    return word[0:8], word[12 :16] 

bus = SMBus(1)

temp_binary = format(bus.read_word_data(0x18, 0x05),'016b')
LSB, MSB = word_To_LSB_MSB(temp_binary)
print("{:.1f}".format(float(int(MSB + LSB,2)) / 16))
