import os
import time
from datetime import datetime, timedelta
import threading
import subprocess
import sys
import socket
class DeadmansSwitch:
    
    def createDeadman(self, addr):
        raise NotImplementedError("Not implemented properly")
        self.deadman = multiprocessing.Process(target=DeadmansSwitch.deadmansHold, args=(addr,))
        self.deadman.start()
    def stopDeadman(self):
        raise NotImplementedError("Not implemented properly")
        self.deadman.kill()

    def createSwitch(self):
        self.switch = subprocess.Popen(
            ["C:/Python314/pythonw.exe", "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/PQPC/DeadMansSwitch.py"],
            creationflags=( subprocess.DETACHED_PROCESS |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )

    def createTwoWaySwitch(self, timeout=1.0):
        #creates an external process called via main()
        self.program = subprocess.Popen(
            ["C:/Python314/pythonw.exe", "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/PQPC/DeadMansSwitch.py", "both","1618",str(timeout)],
            creationflags=( subprocess.DETACHED_PROCESS |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        return threading.Thread(target=DeadmansSwitch.twoWaySwitch,args=(1619,1618,timeout))


    def stopSwitch(self):
        self.switch.kill()

    def deadmansHold(port=1618, pingDelay=0.4):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        while True:
            try:
                sock.sendto(b"alive", ("127.0.0.1", port))
                time.sleep(pingDelay)
            except:
                continue

    def loopCheckSwitchHoldStatus(port=1618, timeout = 1):
        while True:
            try:
                    
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.bind(("127.0.0.1", port))
                s.settimeout(timeout)
                while True:
                    try:
                        data, _ = s.recvfrom(1024)
                        # heartbeat received, do nothing
                    except socket.timeout:
                        os.system('shutdown /s /t 2 /c "Deadman\'s switch activated.\nNO CHEATING!"')
                        return
            except:
                continue

    def twoWaySwitch(portA=1618, portB=1619, timeout=1):
        # --- switch A poll checker 
        switchLastPoll = datetime.now()
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.bind(("127.0.0.1", portA))
        s.settimeout(timeout)

        # --- deadmans hold for switch B
        deadmanLastHold = datetime.now()
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        
        # --- start loop
        while True:
            now = datetime.now()

            try:
                sock.sendto(b"alive", ("127.0.0.1", portB))
                deadmanLastHold = now
            except:
                continue

            try:
                data, _ = s.recvfrom(1024)
            except socket.timeout:
                os.system('shutdown /s /t 300 /c "Deadman\'s switch activated.\nNO CHEATING!"')
                return
            timeTaken = datetime.now()-now
            time.sleep(max(0,timeout-timeTaken.total_seconds()))

    def stop(self):
        self.isActive = False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        pass
    else:
        _ = sys.argv[0]
        programType = sys.argv[1]
        port = int(sys.argv[2])              
        delay = float(sys.argv[3])

        if programType == "switch":
            DeadmansSwitch.loopCheckSwitchHoldStatus(port,delay)
        elif programType == "hold":
            DeadmansSwitch.deadmansHold(port,delay)
        elif programType == "both":
            DeadmansSwitch.twoWaySwitch(port,port+1,delay)
