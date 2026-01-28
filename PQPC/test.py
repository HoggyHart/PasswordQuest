import threading

lock = threading.Lock()

list = [0,1,2,3,4,5,6,7,8,9,10,10,12,11]
delCount = 0
for i in range(len(list)):
    print(i-delCount)
    if list[i-delCount]%2 == 0:
        list.remove(list[i-delCount])
        delCount+=1
        continue

print(list)