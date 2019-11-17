import numpy as np
from math import log
import matplotlib.pyplot as plt

def norm(l):
    x2 = [x*x for x in l]
    return sum(x2)

def invsqrt(n):
    return 1/(n)**0.5

def sainvsqrt(n):
    bits = 16
    toShift = bits - int(log(n,2))
    y = 1 << (toShift//2)

    for i in range(5):
        # three in fixed point
        three = 3<<bits

        # convert back to f16 for y
        y = y * (three - ((n*y)*y)) >> bits + 1
    
    return y

def ainvsqrt(n):
    bits = 16
    toShift = bits - int(log(n,2))
    y = 1 << bits + (toShift//2)

    for i in range(2):
        # three in fixed point
        three = 3<<bits

        # convert back to f16 for y
        y = y * (three - ((n*y>>bits)*y>>bits)) >> bits + 1
    
    return y/2.**16

@np.vectorize
def ratio(n):
    x = int(n**2)
    approx = sainvsqrt(x>>16)*15//16
    true = invsqrt(x)*2**16
    return approx / true

ns = np.linspace(256, 10000, num=1000)
plt.plot(ns, ratio(ns))
plt.plot(ns, [1]*len(ns))
plt.plot(ns, [0.87]*len(ns))
plt.show()
