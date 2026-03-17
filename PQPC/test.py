import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading
import socket
import sys
from datetime import datetime, timedelta
import time
import DeadMansSwitch
import psutil
import pygetwindow as gw

import ThreadUtils


myUtil = ThreadUtils.ThreadUtility()

myUtil.acquireLock("firstLock")
myUtil.acquireLock("secondLock")
myUtil.releaseLock("firstLock")
myUtil.acquireLock("firstLock")

print("escaped")