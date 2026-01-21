
class MyServer(SimpleHTTPRequestHandler):

    def do_GET(self):
        print("someones getting")
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_POST(self):
        global keysLock, schedules
        print("Received POST to",self.path)
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        message = post_data.decode('utf-8')
        print("Received:")
        print(repr(message))

        if(self.path == "/synchronise/schedules"):
            self.synchroniseSchedules(message)
            return
        elif(self.path == "/synchronise/schedule"):
            self.synchroniseSchedule(message)
            return
        else:
            self.addKey(message)
            return
        #else:
      #      print("hmmm...")

        print(f"Received POST data: {post_data.decode('utf-8')}")
        
        self.send_response(400)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        response_message = f"POST request received successfully! But sent to unknown path: {self.path}"
        self.wfile.write(bytes(response_message))

    def synchroniseSchedules(self, schJsons: str):
        global keysLock, fileLock, schedules
        print("Received synchronisation POST request")
        #post load comes in split by \r\n\r\n
        schList = schJsons.split("\r\n\r\n")
        print("Received schedules:")
        for s in schList:
            print("===========================")
            print(s)
        print("===========================")

        #overwrite all schedules
        print("Waitin for FileLock")
        fileLock.acquire_lock()
        print("Acquired for FileLock")
        schFile = open(scheduleFileDir,"w")
        schFile.write(schJsons.replace("\r\n\r\n","\n\n"))
        schFile.close()
        fileLock.release_lock()
        print("Rleased for FileLock")

        #overwrite global schedules list
        try:
            print("Synchronising....") 
            print("                     --"+threading.current_thread().name+": WAITING schedulesLock")
            schedulesLock.acquire_lock()
            print("                     --"+threading.current_thread().name+": ACQUIRED schedulesLock")
            schedules = []
            for sch in schList:
                schedule = Schedule(sch)
                print(schedule.toJson())
                schedules.append(schedule)
        except Exception as e:
            print("ERROR SYNCHRONISING",e)

        schedulesLock.release_lock()
        print("                     --"+threading.current_thread().name+": RELEASED schedulesLock")
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

    def synchroniseSchedule(self, schJson):
        global schedules
        try:
            schedule = Schedule(schJson)
            ThreadUtils.acquireLock(fileLock, "File Lock")
            schedule.saveToFile()
            ThreadUtils.releaseLock(fileLock, "File Lock")
            print(schedule.toJson())

            updateForExistingSchedule = False
            ThreadUtils.acquireLock(schedulesLock, "Schedules Lock")
            for i in range(len(schedules)):
                if schedule.questUUID == schedules[i].questUUID:
                    schedules[i] = schedule
                    updateForExistingSchedule = True
                    break
            if not updateForExistingSchedule:
                schedules.append(schedule)
        except Exception as e:
            print("     FAILED to decode json:",e)
        ThreadUtils.releaseLock(fileLock, "File Lock")
        ThreadUtils.releaseLock(schedulesLock, "Schedules Lock") 
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

    def addKey(self, key):
        global keysLock
        print("appending to keys")
    #   global received_keys, keysLock
        print("                     --"+threading.current_thread().name+": WAITING keysLock")
        keysLock.acquire_lock()
        print("                     --"+threading.current_thread().name+": ACQUIRED keysLock")
        received_keys.append(key)
        keysLock.release_lock()
        print("                     --"+threading.current_thread().name+": RELEASED keysLock")
        print("finished appending to keys")
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)
   