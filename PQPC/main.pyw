import subprocess
import os
import io, sys
import socket
import logger
from PQCONSTS import PQLOG, DEBUGMODE, SHUTDOWNDELAY
import ComputerControl
def ensureProgramStarted():
    #actual program sends ping to this socket when started. wait for ping to ensure program has started/hasnt been clsoed before actually starting
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("127.0.0.1", 1617))
    s.settimeout(8)
    try:
        data, _ = s.recvfrom(1024)
        s.close()
        return True
    except:
        s.close()
        return False

if __name__ == "__main__":
    try:
        PQLOG.debug("Program started")
        if not DEBUGMODE:
            ComputerControl.blockInput() #input is unblocked in main program
        subprocess.Popen(
            ["C:/Python314/python.exe", "C:/Users/willi/Desktop/code/PasswordQuest/PQPC/PQGUI/PasswordQuest.py"],
                creationflags=( subprocess.DETACHED_PROCESS |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                )
        
       # if not ensureProgramStarted():
       #     PQLOG.critical("Program was not found to have started properly. Shutting down.")
       #     os.system('shutdown /s /t '+str(SHUTDOWNDELAY)+' /c "Deadman\'s switch activated - Program did"')

    except Exception as e:
        PQLOG.critical(str(e))
        ComputerControl.unblockInput()