import os
import time
from datetime import datetime, timedelta
import threading
import subprocess
import sys
import socket
import psutil

global isActive
isActive = True
import logger

class DeadmansSwitch:


    def createTwoWaySwitchV2(self, processName: str):
        #creates an external process called via main()
        self.switch = subprocess.Popen(
            ["C:/Python314/pythonw.exe", "C:/Users/willi/Desktop/code/PasswordQuest/PQPC/DeadMansSwitch.py", processName],
            creationflags=( subprocess.DETACHED_PROCESS |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        return threading.Thread(target=DeadmansSwitch.deadmansSwitchV2,args=('DeadMansSwitch.py',))

    def deadmansSwitchV2(scriptName: str):
        while isActive:
            if not DeadmansSwitch.scriptIsRunning(scriptName):
                os.system('shutdown /s /t 5 /c "Deadman\'s switch activated.\nNO CHEATING!"')
                return
            time.sleep(0.5)

    def scriptIsRunning(scriptFileName: str):
        processes = [p.cmdline() for p in psutil.process_iter() if "python" in p.name().lower()]
        matchingScripts = [p for p in processes if scriptFileName in p[1]]

        if len(matchingScripts) > 0:
            return True
        return False

    def stopAllSwitches(self):
        global isActive
        isActive = False
        self.switch.kill()
        #self.isActive = False

if __name__ == "__main__":
    print(sys.argv)
    #arg1 = file name
    if len(sys.argv) < 2:
        pass
    elif len(sys.argv) == 2:
        #pass name of script
        DeadmansSwitch.deadmansSwitchV2(sys.argv[1])
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
