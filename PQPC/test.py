import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading

try:
    raise RuntimeError("error!")
except Exception as e:
    print("Error: "+str(e))