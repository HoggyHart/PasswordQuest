#import webStuff
#import random
#import os
#import keyboard, mouse
import threading
#import pywhatkit
import time
import win32api, win32con
import pygetwindow as gw

from http.server import HTTPServer, SimpleHTTPRequestHandler


# LOCK STUFF ---------------------------------------------------------------------------------------------------------

# SERVER STUFF ---------------------------------------------------------------------------------------------

from datetime import datetime, timedelta
#from ThreadUtils import acquireLock, releaseLock
import ThreadUtils
from Schedule import Schedule
import json
import subprocess
#import re
from winwifi import WinWiFi
from DeadMansSwitch import DeadmansSwitch
global received_keys, computerLocked, lockedUntilNextQuestCompletionOREOD, schedules, keysLock, connected, PQ_Server, deadmansSwitch
#schedules defined after Schedule class def
deadmansSwitch = DeadmansSwitch()
received_keys: list[str] = []
computerLocked = False
lockedUntilNextQuestCompletionOREOD = False
keysLock = threading.Lock() 
schedulesLock = threading.Lock()
fileLock = threading.Lock()
scheduleFileDir = "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/schedules.txt"
connected = False
schedules: list[Schedule] = []

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
        
global attemptingConnection
attemptingConnection = False

def connectToPrivateNetwork():
    global connected, attemptingConnection

    attemptingConnection = True
    connectionProgressPadding = "                                                                                              ==CONNECTION PROGRESS== ||| "
    
    network_SSID = "WillPhone"
    network_Password = "poopoo1!"
    try:
        networks = WinWiFi.scan()
    except Exception as e:
        print(connectionProgressPadding+"Error scanning networks: ",e)
        attemptingConnection = False
        return
    networkList = []
    print(connectionProgressPadding+"Visible Networks: ")
    for n in networks:
        print(connectionProgressPadding+"Found: "+n.ssid)
        networkList.append(n.ssid.strip())

    print(connectionProgressPadding+"Checking for "+network_SSID+"...")
    if network_SSID in networkList:
        print(connectionProgressPadding+"Network found, attempting to connect...")
        status = subprocess.run("netsh wlan connect "+network_SSID, capture_output=True).stdout.decode()
        print(connectionProgressPadding+status)
        #output from cmd is "Connection request was completed *success*fully" if success
        time.sleep(5)
        connected = status.strip() == "Connection request was completed successfully."
    else:
        print(connectionProgressPadding+"Quest Network not found...")
        connected = False
    attemptingConnection = False

PQ_Server: HTTPServer = None
def hostServer():
    serverThreadPadding = "                                                                                                                                            ==SERVER THREAD== ||| "
    global connected, PQ_Server
    while(True):
        if connected:
            print(serverThreadPadding+"Attempting host")
            try:
                PQ_Server = HTTPServer(('172.20.10.5', 1617), MyServer)
                print(serverThreadPadding+"Server created!")
                PQ_Server.serve_forever()
            except:
                print(serverThreadPadding+"Failed to continue hosting server, trying again in 5 seconds...")
                time.sleep(5)
        #should only NOT be connected if there is no need or want to be.
        #quest is active -> connectToPrivateNetwork() gets called until connected = true
        #user wants to synchronise schedules -> manual connection -> this else: code checks if its connnected -> connected = true (if it is)
        else:
            print(serverThreadPadding+"Not connected to Quest Network, retrying host in 3 seconds")
            time.sleep(3)

def pollConnection():
    pollThreadPadding = "                                                                                                                                                                                    ==CONNECTION POLL== ||| "
    global connected, PQ_Server
    while(True):
        try:
            print(pollThreadPadding+"Scanning networks...")
            wifi = subprocess.check_output(['netsh', 'WLAN', 'show', 'interfaces'])
        except:
            print(pollThreadPadding+"Failed to scan networks")
            connected = False
            continue
        data = wifi.decode('utf-8')
        if "WillPhone" in data:
            print(pollThreadPadding+"Result: Connected to QuestNetwork")
            connected = True
        else:
            print(pollThreadPadding+"Result: Not connected to QuestNetwork")
            try:
                print(pollThreadPadding+"Attempting to shut down server")
                PQ_Server.shutdown()
            except Exception as e:
                print(pollThreadPadding+"No server to shut down")
            connected= False
        time.sleep(5)

def newMain():
    global received_keys, computerLocked, lockedUntilNextQuestCompletionOREOD, schedules, keysLock, connected, schedulesLock, deadmansSwitch
    try:
        print("Locking during init...")

        #---Create a deadmans switch
        #create another process that checks for pings to tcp://localhost:1617
        deadmansSwitch.createSwitch() #can be stopped via deadmansSwitch.stop() (hopefully)
        #create a thread that sends pings to ttcp://localhost:1617
        deadmanThread = threading.Thread(target=DeadmansSwitch.deadmansHold)
        deadmanThread.start()
        #if this program gets ended, the pings stop sending and switch is 'released', causing a PC shutdown


        
      #  screen_off()
        computerLocked = True
        print("==========================================================================================================COMPUTER LOCKED==========================================================================================================")

        print("Starting program")
        schedules = Schedule.readListFromFile(scheduleFileDir)
        serverThread = threading.Thread(target=hostServer)
        serverThread.start()

        connectionThread = threading.Thread(target=pollConnection)
        connectionThread.start()
        while(True):
            now = datetime.now()

            questsInProgress = False

            #check if key received to end progress of quest
            #check if quest scheduled to start
            #global keysLock
            print("Checking schedules")
            print("                     --"+threading.current_thread().name+": WAITING schedulesLock")
            schedulesLock.acquire_lock()
            print("                     --"+threading.current_thread().name+": ACQUIRED schedulesLock")
            for schedule in schedules:
                print("Inspecting "+schedule.scheduleName)
                #if quest currently active 
                #   -> key received? endQuest()
                #   -> not received? questsInProgress = True
                if schedule.questInProgress:
                    print("Waiting for key for "+schedule.scheduleName)
                    actualEndTime = schedule.startTime + (schedule.scheduledEndTime - schedule.scheduledStartTime)
                    print("     Scheduled from "+schedule.startTime.__str__()+" to "+actualEndTime.__str__())
                    #if quest in progress then the only the pc should be doing is trying to allow the user to unlock the pc
                    if not connected and not attemptingConnection:
                        #connecting to the network will make the hostServer thread start attempting to host the server
                        threading.Thread(target=connectToPrivateNetwork).start()
                    

                    #try ending active scheduled quest, no need to check if no schedule end keys have been received
                    if len(received_keys) > 0:
                        #if active, may be pending on key to end
                        scheduleEndKey = schedule.questUUID  
                        print("                     --"+threading.current_thread().name+": WAITING keysLock")
                        keysLock.acquire_lock()
                        print("                     --"+threading.current_thread().name+": ACQUIRED keysLock")
                        for key in received_keys:
                            if scheduleEndKey in key:
                                finishedOnTime = key.split('_')[1]
                                print("Key received for "+schedule.scheduleName)
                                if finishedOnTime == "YES":
                                    print(schedule.scheduleName + " completed on time!\n")
                                    schedule.endQuest()
                                    schedule.saveToFile()
                                    lockedUntilNextQuestCompletionOREOD = False
                                    break
                                else:
                                    print(schedule.scheduleName + " failed.\n")
                                    schedule.endQuest()
                                    schedule.saveToFile()
                                # lockedUntilNextQuestCompletionOREOD = True
                                    lockedUntilNextQuestCompletionOREOD = False
                                    break
                        keysLock.release_lock()
                        print("                     --"+threading.current_thread().name+": RELEASED keysLock")
                    else:
                        print("No keys received\n")
                    questsInProgress = True
                #if scheduled quest inactive, see if it needs to start
                elif schedule.isActive:
                    actualEndTime = schedule.startTime + (schedule.scheduledEndTime - schedule.scheduledStartTime)
                    print("Checking if "+schedule.scheduleName+" should start ("+schedule.startTime.__str__()+" - "+actualEndTime.__str__()+")")
                    if schedule.startTime <= now:
                        print("Starting",schedule.scheduleName+"'s quest lockdown\n")
                        schedule.questInProgress = True
                        schedule.saveToFile()
                    else:
                        print("Not time.\n")
                else:
                    print(schedule.scheduleName, "not active\n")
            schedulesLock.release_lock()
            print("                     --"+threading.current_thread().name+": RELEASED schedulesLock")
            
            #check computer lock status
            if (questsInProgress or lockedUntilNextQuestCompletionOREOD):
                print("==========================================================================================================COMPUTER LOCKED==========================================================================================================")
               # screen_off()
                
                win = gw.getWindowsWithTitle('C:\\Program Files\\WindowsApps\\PythonSoftwareFoundation.Python.3.11_3.11.2544.0_x64__qbz5n2kfra8p0\\python3.11.exe')[0] 
                win.activate()
                computerLocked = True
            else:
                print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++COMPUTER UNLOCKED++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
                screen_on()
                computerLocked = False
            time.sleep(5)
    except Exception as e:
        deadmansSwitch.stopSwitch()
        print(e)
        screen_on()
        input()

if __name__ == "__main__":
    newMain()

#PROGRAM FLOW
# 
# IOS APP - FUNCTIONS AS QUEST TRACKER/SCHEDULER:
#   USER CAN CREATE QUESTS, TASKS, SCHEDULES.
#   WHEN CHANGES ARE MADE TO A SCHEDULE -> UI ELEMENT TO INDICATE PROPER SAVE OR NOT
#   - TO PROPER SAVE:
#       PC MUST CONNECT TO MOBILE HOTSPOT/PRIVATE NETWORK
#       IOS SENDS POST TO 172.20.10.5:1617 (PC) WITH SCHEDULE INFO
#       PC SAVES SCHEDULE INFO IN TXT FILE (for now)
#       PC SENDS BACK "YEAH ALL SORTED"
#   
#   IOS APP TRACKS AND UPDATES QUEST AND TASK DATA FOR IPHONE SENSORS (home ones should be stored on home device i.e. PC or microcontroller/whatever)
#   WHEN QUEST FINISHES, MARK COMPLETION TIME (AUTO-DONE WITH LASTUPDATE) ON ASSOCIATED SCHEDULE.
#   WHEN TRYING TO GET BACK ON PC, TURN ON HOTSPOT SO PC CAN CONNECT, THEN KEEP TRYING TO SEND POST REQUEST WITH JSON KEY OF $SCHEDULE_UUID+'_'+TRUE, ALSO SEND
#       IF QUEST NOT COMPLETED ON TIME, SEND POST REQUEST WITH $SCHEDULE_UUID+'_'+FALSE

# PC APP - FUNCTIONS AS LOCKDOWN SCHEDULER - USES SAME SCHEDULE INFO AS IOS APP, RECEIVED VIA HTTP POST REQUESTS - WHEN SCHEDULE STARTS LOCKS DOWN PC UNTIL RECEIVING THE SCHEDULE UUID AND ON-TIME-COMPLETION STATUS AS POST REQUEST:
#   HOLDS SCHEDULE INFO
#   CONSTANTLY IN BACKGROUND LOOPING OVER:
#       ACTIVE SCHEDULES:
#           SHOULD I START A SCHEDULED QUEST? -> YES? MARK SCHEDULED QUEST (UUID) AS IN-PROGRESS
#           IS A SCHEDULED QUEST IN PROGRESS? -> 
#               1. START/CONTINUE LOCK DOWN AND KEEP TRYING TO CONNECT TO PRIVATE NETWORK FOR RECEIVING KEYS
#               2. CHECK RECEIVED_KEYS -> IS THERE A RECEIVED_KEY? DOES IT MATCH AN IN-PROGRESS SCHEDULE'S UUID AND HAVE TRUE AT THE END? -> MARK SCHEDULE NOT IN-PROGRESS AND UPDATE SCHEDULE_START_TIME. ALSO REMOVE RECEIVED_KEY
#                   2B. IF KEY HAS NIL/FALSE AT THE END, DO APPROPRIATE FAILURE RESPONSE (COULD BE NOTHING, COULD BE FLAG LOCKDOWN_UNTIL_TOMORROW AS TRUE)
#                   2C. IF KEY DOESNT MATCH ANYTHING, DISCARD IT
#           
#   
#   PASSIVELY LISTENS TO PORT 1617:
#       IF SCHEDULE JSON RECEIVED:
#           IF SCHEDULE IS CAUSING A LOCKDOWN RIGHT NOW, CHECK IF THE NEW SCHEDULE INFO PREVENTS THIS, AND END LOCKDOWN IF SO (user could not have edited schedule to cheese this if the schedule was active when the changes were made)
#               SCHEDULE LOCKDOWN ENDING IS ASSOCIATED WITH UUID SO ENDING THE LOCKDOWN WILL NOT BE AFFECTED
#           ADD/UPDATE SCHEDULE APPROPRIATELY
#           
#       IF questUUID+BOOL JSON RECEIVED, ADD TO RECEIVED_KEYS


#CHANGES TO BE MADE TO IOS APP: SCHEDULE'S SHOULD TRACK VIA BOOL IF THEY ARE SYNCHRONISED WITH THE PC LOCK SERVER OR NOT
#   UPON CHANGES, BOOL "SYNCHRONISED" = FALSE
#   WHILE SYNCHRONISED == FALSE -> ATTEMPT HTTP POST REQUEST, IF RESPONSE RECEIVED (200) THEN MARK AS TRUE
#   UNSYNCHRONISED SCHEDULES CAN STILL START WITH THEIR NEW SCHEDULE STUFF


#main()