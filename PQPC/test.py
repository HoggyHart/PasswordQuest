import random
import time
tottot = 0
num = 100000
for number in range(0,num):
    i = 1000
    tot = 0
    random.seed()
    while i > 0:
        i -= 1
        if random.random() >0.996:
            i += 75
        tot += 1
    tottot += tot

print("avg: ",tottot/num)