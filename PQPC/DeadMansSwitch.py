import os
import time
from datetime import datetime, timedelta
import threading
import subprocess
import sys
import psutil

global isActive
isActive = True
import logging

log = logging.getLogger("root")
class DeadmansSwitch:


    def createTwoWaySwitchV2(self, processName: str, shutdownDelay: int):
        #creates an external process called via main()
        self.switch = subprocess.Popen(
            ["C:/Python314/pythonw.exe", "C:/Users/willi/Desktop/code/PasswordQuest/PQPC/DeadMansSwitch.py", processName, str(shutdownDelay)],
            creationflags=( subprocess.DETACHED_PROCESS |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        return threading.Thread(target=DeadmansSwitch.deadmansSwitchV2,args=('DeadMansSwitch.py',shutdownDelay))

    def deadmansSwitchV2(scriptName: str, shutdowndelay: int):
        while isActive:
            if not DeadmansSwitch.scriptIsRunning(scriptName):
                if isActive:
                    log.critical("Did not find "+scriptName+"! Shutting down...")
                    os.system('shutdown /s /t '+str(shutdowndelay)+' /c "Deadman\'s switch activated.\nNO CHEATING!"')
                return
            time.sleep(0.5)

    def scriptIsRunning(scriptFileName: str):
        try:
            processes = [p.cmdline() for p in psutil.process_iter() if "python" in p.name().lower()]
            #print(processes)
            matchingScripts = [p for p in processes if scriptFileName in p[1]]
            if len(matchingScripts) > 0:
                return True
            return False
        except psutil.NoSuchProcess: # error during iterations. if deadmans program is not running then no error should be thrown.
            return True
        except Exception as e:
            log.critical("Could not scan processes!"+str(e))
            return False

    #inversed: True if dms should timeout if it CAN find program
    #           False if dms should timeout if it CANT find program
    def oneTimeTimeout(scriptName: str, timeout: float, inversed: bool):
        startTime = datetime.now()
        timeouttd = timedelta(seconds=timeout)
        while (datetime.now()-startTime).total_seconds() < timeouttd:
            if not DeadmansSwitch.scriptIsRunning(scriptName):
                if inversed: 
                    pass
                else:
                    return False
        return False
    def stopAllSwitches(self):
        global isActive
        isActive = False
        self.switch.kill()
        #self.isActive = False

if __name__ == "__main__":
    print(sys.argv)
    #arg1 = file name
    if len(sys.argv) < 3:
        pass
    elif len(sys.argv) == 3:
        #pass name of script
        DeadmansSwitch.deadmansSwitchV2(sys.argv[1], sys.argv[2])