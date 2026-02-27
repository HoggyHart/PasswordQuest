import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading
import socket
import sys
from datetime import datetime, timedelta
import time
import DeadMansSwitch



def main():
    deadmansSwitch = DeadMansSwitch.DeadmansSwitch()
    deadmansThread = deadmansSwitch.createTwoWaySwitch(0.5)
    print(deadmansThread.__str__())
    deadmansThread.start()
    deadmansThread.join()
    input()

if __name__ == "__main__":
    main()