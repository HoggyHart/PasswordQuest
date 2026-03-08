import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading
import socket
import sys
from datetime import datetime, timedelta
import time
import DeadMansSwitch
import psutil

def checkIfScriptRUnning(scriptFileName):
    processes = [p.cmdline() for p in psutil.process_iter() if "python" in p.name().lower()]
    matchingScripts = [p for p in processes if scriptFileName in p[1]]

    if len(matchingScripts) > 0:
        print("Running")