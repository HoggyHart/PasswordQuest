# watchdog.py
import socket
import time
import os

def watchdog_main(port=50007):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(("127.0.0.1", port))
    s.settimeout(5)

    print("Watchdog running in background")

    while True:
        try:
            data, _ = s.recvfrom(1024)
            # heartbeat received
        except socket.timeout:
            print("No heartbeat. Triggering shutdown.")
            os.system('shutdown /s /t 30 /c "Deadman\'s switch activated"')
            break

if __name__ == "__main__":
    try:
        watchdog_main()
    except Exception as e:
        print("WATCHDOG ERROR:", e)
    finally:
        print("Watchdog exiting. Press Enter to close.")
        input()


while True:
    print("ARGGG")
