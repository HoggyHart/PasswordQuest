import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
import threading

class myserv(SimpleHTTPRequestHandler):

    def do_GET(self):
        print("someones getting")

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        data = bytes("erm hiii!!",'utf-8')
        self.wfile.write(data)


def hostServer():
    PQ_Server = HTTPServer(('127.0.0.1', 2468), myserv)
    print("Server created!")
    PQ_Server.serve_forever()
    print("failed")

serverThread = threading.Thread(target=hostServer)
serverThread.start()

print(requests.put("http://127.0.0.1:2468"))