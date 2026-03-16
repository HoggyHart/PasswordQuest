import subprocess
import os
from DeadMansSwitch import DeadmansSwitch
import socket
import logger
def ensureProgramStarted():
    #actual program sends ping to this socket when started. wait for ping to ensure program has started/hasnt been clsoed before actually starting
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("127.0.0.1", 1617))
    s.settimeout(7)
    try:
        data, _ = s.recvfrom(1024)
        s.close()
        return True
    except:
        s.close()
        return False

if __name__ == "__main__":
    try:
        log = logger.set_debug_logger("root")
        log.debug("Program started")
        subprocess.Popen(
            ["C:/Python314/python.exe", "C:/Users/willi/Desktop/code/PasswordQuest/PQPC/PQGUI/PasswordQuest.py"]
            
                )
        #create a mini deadmans switch here that tries to get the signal that the process DID start (i.e. didnt get closed early)
        # and shuts down if it doesnt get it within 10 seconds

        if not ensureProgramStarted():
            log.critical("Program was not found to have started properly. Shutting down.")
            os.system('shutdown /s /t 5 /c "Deadman\'s switch activated.\nNO CHEATING!"')

    except Exception as e:
        print(e)
        input()
        