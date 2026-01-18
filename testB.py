#
#   Hello World client in Python
#   Connects REQ socket to tcp://localhost:5555
#   Sends "Hello" to server, expects "World" back
#

import zmq
import time
context = zmq.Context()

#  Socket to talk to server
print("Connecting to hello world server…")
socket = context.socket(zmq.PUSH)
socket.connect("tcp://localhost:5555")

#  Do 10 requests, waiting each time for a response
while (True):
    print(f"Sending request…")
    try:
        socket.send(b"wzzup",zmq.NOBLOCK)
        print ("  succeed")
    except:
        print ("  failed")
    time.sleep(1)