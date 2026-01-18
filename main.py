# main.py
import subprocess
import time
import socket
import sys
import os

def start_watchdog():
    script_dir = os.path.curdir
    print(os.path.join(script_dir,"/watchdog.py"))

    return subprocess.Popen(
        [sys.executable, os.path.join(script_dir,"/watchdog.py")],
        creationflags=( subprocess.CREATE_NEW_CONSOLE |
                       subprocess.CREATE_NEW_PROCESS_GROUP),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL
    )

if __name__ == "__main__":
    start_watchdog()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    print("Main program running. Close this terminal to test the deadman’s switch.")

    while True:
        sock.sendto(b"alive", ("127.0.0.1", 50007))
        time.sleep(1)
