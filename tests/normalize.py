import numpy as np
from math import log

def norm(l):
    x2 = [x*x for x in l]
    return sum(x2)

def invsqrt(l):
    return 1/(norm(l))**0.5

def ainvsqrt(n):
    bits = 16
    toShift = bits - int(log(n,2))
    y = 1 << (toShift//2)
    print(f"y guess: {y}")

    for i in range(2):
        # three in fixed point
        three = 3<<bits

        # convert back to f16 for y
        y = y * (three - ((n*y)*y)) >> bits + 1
        
    return y

for x in range(8):
    v = np.array([-250, 250, 400])*2**(x/2)
    i = int(norm(v))
    print(f"num: {ainvsqrt(i>>16)}")
    print(f"i: {i**0.5/2**16}, approx/norm: {(ainvsqrt(i>>16)*7//8)/(invsqrt(v/2**16))}")
