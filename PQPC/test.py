import requests
from datetime import datetime
import threading
from http.server import SimpleHTTPRequestHandler, HTTPServer
import iOS_PQPrototypeWaiter
import time
import json

#t = iOS_PQPrototypeWaiter.PasswordQuestServer()

#threading.Thread(target=t.run).start()


class testStruct:
    def __init__(self, n, s):
        self.num = n
        self.string = s
    
    def __repr__(self):
        return self.toJson().__str__()
    
    def toJson(self):
        meJson = {
            'num':self.num,
            'string':self.string
        }
        return meJson

    def fromJson(data):
        return testStruct(data['num'],data['string'])
    
    def custom_json(obj):
        if isinstance(obj, complex):
            return {'__complex__': True, 'real': obj.real, 'imag': obj.imag}
        raise TypeError(f'Cannot serialize object of {type(obj)}')
    

myList = []
for i in range(0,10):
   myList.append(testStruct(i, "ABCDEFGHIJK"[i]))
   #myList.append(i)
print(myList)

myJson = json.dumps({'list':myList},default=testStruct.toJson,indent=4)
#print(myJson)
myList = [testStruct.fromJson(s) for s in json.loads(myJson)['list'] ]
print(myList[3])

print("0"==True)
print("1"==True)

#print(json.dumps({'test':datetime.now()}))
print(json.loads("{\"tst\":\"false\"}"))
js = json.loads("{\"tst\":\"false\"}")
print(js['tst']==False)
print(js['tst']=="false")