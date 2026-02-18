import os
import time
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

    def stopSwitch(self):
        self.switch.kill()

    def deadmansHold(port=1618):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        while True:
            sock.sendto(b"alive", ("127.0.0.1", port))
            time.sleep(2)

    def switchHeldPollerStatic(port=1618):
        while True:
            try:
                    
                s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                s.bind(("127.0.0.1", port))
                s.settimeout(5)
                while True:
                    try:
                        data, _ = s.recvfrom(1024)
                        # heartbeat received
                    except socket.timeout:
                        os.system('shutdown /s /t 0 /c "Deadman\'s switch activated.\nNO CHEATING!"')
                        return
            except:
                continue

    def stop(self):
        self.isActive = False

if __name__ == "__main__":
    DeadmansSwitch.switchHeldPollerStatic()
    input()