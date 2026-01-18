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

    def createSwitch(self, addr):
        self.switch = subprocess.Popen(
            [sys.executable, "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/DeadMansSwitch.py"],
            creationflags=( subprocess.CREATE_NEW_CONSOLE |
                        subprocess.CREATE_NEW_PROCESS_GROUP),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL
        )
        self.switch.start()
    def stopSwitch(self):
        self.switch.kill()

    def deadmansHold(port=1618):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        while True:
            sock.sendto(b"alive", ("127.0.0.1", port))
            time.sleep(1)

    def switchHeldPollerStatic(port=1618):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.bind(("127.0.0.1", port))
        s.settimeout(1.5)
        while True:
            try:
                data, _ = s.recvfrom(1024)
                # heartbeat received
            except socket.timeout:
                os.system('shutdown /s /t 30 /c "Deadman\'s switch activated.\nNO CHEATING!"')
                break

    def stop(self):
        self.isActive = False

if __name__ == "__main__":
    DeadmansSwitch.switchHeldPollerStatic()