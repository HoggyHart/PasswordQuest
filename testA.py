#
#   Hello World server in Python
#   Binds REP socket to tcp://*:5555
#   Expects b"Hello" from client, replies with b"World"
#

import time
import zmq
import time
from DeadMansSwitch import DeadmansSwitch
import threading
#context = zmq.Context()
#socket = context.socket(zmq.PULL)
#socket.bind("tcp://*:5555")
if __name__ == "__main__":
    if False:
        sw = DeadMansSwitch.DeadmansSwitch("tcp://*:5555")
        swThred = threading.Thread(target=sw.switchHeldPoller)
        swThred.start()

        time.sleep(2)
        print("----------------------------------------------------------------------------------------------------------------------")
        sw.createDeadman()
        print("======================================================================================================================")
        time.sleep(10)
        sw.stopDeadman()
        time.sleep(5)
        sw.stop()
        time.sleep(5)

print("POPOOO")