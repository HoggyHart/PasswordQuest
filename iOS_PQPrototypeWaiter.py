#import webStuff
#import random
#import os
#import keyboard, mouse
import threading
#import pywhatkit
import time
#import win32gui
import win32con
#import pygetwindow as gw 
#from pywhatkit.core import core
#import webbrowser as web
import win32api
#import pyautogui

import time
import ctypes
import win32api, win32con

from http.server import HTTPServer, SimpleHTTPRequestHandler


# LOCK STUFF ---------------------------------------------------------------------------------------------------------
def screen_off():
  #  ctypes.windll.user32.SendMessageW(65535, 274, 61808, 2)
    ctypes.windll.user32.BlockInput(True)
    pass
def screen_on():
 #   ctypes.windll.user32.SendMessageW(65535, 274, 61808, -1)
    ctypes.windll.user32.BlockInput(False)
    move_cursor()
    
def move_cursor():
    x, y = (0,0)
    win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, x, y)

def lockStuff():
     #turn screen off so user has trouble interfering
    screen_off()
    print("STARTING")
    ctypes.windll.user32.BlockInput(True)
    time.sleep(3)
    screen_on()
    ctypes.windll.user32.BlockInput(False)
    print("FINISHING")
    
# SERVER STUFF ---------------------------------------------------------------------------------------------

from datetime import datetime, timedelta
import json
import subprocess
#import re
from winwifi import WinWiFi
global received_keys, computerLocked, lockedUntilNextQuestCompletionOREOD, schedules, keysLock, connected, PQ_Server
#schedules defined after Schedule class def
received_keys: list[str] = []
computerLocked = False
lockedUntilNextQuestCompletionOREOD = False
keysLock = threading.Lock() 
schedulesLock = threading.Lock()
fileLock = threading.Lock()
scheduleFileDir = "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/schedules.txt"
connected = False

def dateFromJson(txt: str):
    try:
        date,time = txt.split(',')
        time = time.split(' ')[1]

        d = date.split('/')[0]
        m = date.split('/')[1]
        y = date.split('/')[2]

        h = time.split(':')[0]
        mi = time.split(':')[1]
        s = time.split(':')[2]

        newDate = datetime(year=int(y),month=int(m),day=int(d),hour=int(h),minute=int(mi),second=int(s))
        
        return newDate
    except:
        return None
def dateToJson(date: datetime):
    try:
        txt = ""
        txt += str(date.day) + "/"
        txt += str(date.month) +"/"
        txt += str(date.year) + ", "
        txt += str(date.hour) + ":"
        txt += str(date.minute) + ":"
        txt += str(date.second)
        return txt
    except:
        return "nil"
def boolFromJson(txt: str):
    if txt == "False":
        return False
    return True

class Schedule:
    #isActive: bool
    #questInProgress: bool
    #startTime: datetime
    #scheduledEndTime: datetime
    #scheduledStartTime: datetime
    #scheduleName: str
    #scheduleUUID: str
    #
    #scheduleInfo_everyXDays: bool
    #scheduleInfo_XDayDelay: int
    #scheduleInfo_ScheduledDays: list[bool] = []
    #scheduleInfo_lastCompletionTime: datetime

    def __init__(self, jsonSch):
        #decode from json
        data = json.loads(jsonSch)
        #simple bools
        self.isActive = boolFromJson(data['isActive'])
        self.questInProgress = boolFromJson(data['questInProgress'])
        self.scheduleInfo_everyXDays = boolFromJson(data['schedule_everyXDays'])
        
        #simple string
        self.scheduleName = str(data['scheduleName'])
        self.scheduleUUID = str(data['scheduleUUID'])

        #int
        self.scheduleInfo_XDayDelay = int(data['schedule_XDayDelay'])

        #dates (formatted "dd-mm-yyyy hh:mm::ss" )
        self.startTime = dateFromJson(str(data['startTime']))
        self.scheduledStartTime = dateFromJson(str(data['scheduledStartTime']))
        self.scheduledEndTime = dateFromJson(str(data['scheduledEndTime']))
        self.scheduleInfo_lastCompletionTime = dateFromJson(str(data['schedule_lastCompletionTime']))

        #bitset
        arr = str(data['schedule_scheduledDays'])
        self.scheduleInfo_ScheduledDays = []
        for i in range(0,7):
            #calc from back of val in case of int32, int64, etc. 0s at beginning
            val = arr[len(arr)-1-i]
            self.scheduleInfo_ScheduledDays.insert(0,not (val=="0"))

    def getNext_XDayDelay_StartTime(self, fromDate: datetime) -> datetime:
        return fromDate + timedelta(days=self.scheduleInfo_XDayDelay)

    def getNext_ScheduledDays_StartTime(self, fromDate: datetime) -> datetime:
        curDayOfWeek = fromDate.weekday()

        for i in range(0,7):
            #if day scheduled and first scheduled day found
            if self.scheduleInfo_ScheduledDays[i]==True:
                gap = i - curDayOfWeek

            if self.scheduleInfo_ScheduledDays[i]==True and i > curDayOfWeek:
                gap = i - curDayOfWeek
                break
            
        if gap < 0:
            gap += 7
        return fromDate + timedelta(days=gap)

    def updateStartTime(self):

        dur = self.scheduledEndTime - self.scheduledStartTime

        startMinute = self.scheduledStartTime.minute
        startHour = self.scheduledStartTime.hour
        self.scheduledStartTime = datetime(self.startTime.year,self.startTime.month,self.startTime.day,startHour,startMinute,self.startTime.second)

        if self.scheduleInfo_everyXDays:
            self.scheduledStartTime = self.getNext_XDayDelay_StartTime(self.scheduledStartTime)
        else:
            self.scheduledStartTime = self.getNext_ScheduledDays_StartTime(self.scheduledStartTime)
                                                                 
        self.startTime = self.scheduledStartTime
        self.scheduledEndTime = self.scheduledStartTime + dur

    def saveToFile(self):
        global fileLock

        print("                     --"+threading.current_thread().name+": WAITING fileLock")
        fileLock.acquire_lock()
        print("                     --"+threading.current_thread().name+": ACQUIRED fileLock")
        schFile = open(scheduleFileDir, "r")
        writtenSchedules = schFile.readlines()
        schFile.close()
        schFile = open(scheduleFileDir, "w")
        updateForExistingSchedule = False
        i = 0
        for schJson in writtenSchedules:
            if self.scheduleUUID in schJson:
                writtenSchedules[i] = self.toJson() + "\n"
                updateForExistingSchedule = True
                break
            i+=1
        if not updateForExistingSchedule:
            writtenSchedules.append(self.toJson()  + "\n")
        
        schFile.writelines(writtenSchedules)
        schFile.close()
        fileLock.release_lock()
        print("                     --"+threading.current_thread().name+": RELEASED fileLock")
 
    def endQuest(self):
        self.questInProgress = False
        self.updateStartTime()

    def toJson(self):
        #should be formatted { "isActive" : "True", "questInProgress" : "False", "schedule_everyXDays" : "False", "scheduleName" : "Scheduled New Quest", "scheduleUUID" : "FE61BBA7-2D07-4BBF-B335-1FF8DD12EB2B", "schedule_XDayDelay" : "1", "startTime" : "06/01/2026, 11:09:00", "scheduledStartTime" : "06/01/2026, 11:09:00", "scheduledEndTime" : "06/01/2026, 20:00:00", "schedule_lastCompletionTime" : "05/01/2026, 19:16:45", "schedule_scheduledDays" : "1111111" }
        string = "{\n"
        string += "\"isActive\" : \""+self.isActive.__str__()+"\",\n"
        string += "\"questInProgress\" : \""+self.questInProgress.__str__()+"\",\n"
        string += "\"schedule_everyXDays\" : \""+self.scheduleInfo_everyXDays.__str__()+"\",\n"
        string += "\"scheduleName\" : \""+ self.scheduleName.__str__()+"\",\n"
        string += "\"scheduleUUID\" : \""+ self.scheduleUUID.__str__()+"\",\n"
        string += "\"schedule_XDayDelay\" : \""+self.scheduleInfo_XDayDelay.__str__()+"\",\n"
        string += "\"startTime\" : \""+dateToJson(self.startTime)+"\",\n"
        string += "\"scheduledStartTime\" : \""+dateToJson(self.scheduledStartTime)+"\",\n"
        string += "\"scheduledEndTime\" : \""+dateToJson(self.scheduledEndTime)+"\",\n"
        string += "\"schedule_lastCompletionTime\" : \""+dateToJson(self.scheduleInfo_lastCompletionTime)+"\",\n"
        arr = ""
        for i in range(0,7):
            #calc from back of val in case of int32, int64, etc. 0s at beginning
            val = self.scheduleInfo_ScheduledDays[i]
            if val==False:
                arr += '0'
            else:
                arr += '1'
        string += "\"schedule_scheduledDays\" : \""+arr+"\"\n}"
        return string

    def readListFromFile(schDir):
        global fileLock
        schList: list[Schedule] = []
        try:
            print('loading schedules')
            fileLock.acquire_lock()
            schFile = open(schDir,"r")
            content = schFile.read()
            schs = content.split("\n\n")
            print("============= RAW FILE DATA =============")
            print(repr(content))
            print("=========================================\n")
            for sch in schs:
                print("============= LOADED =============")
                print(sch)
                schList.append(Schedule(sch))
                print("                AS                ")
                print(schList[-1].toJson())
                print("==================================\n")
            schFile.close()
        except Exception as e:
            print("ERROR LOADING: ",e)
            return None
        return schList

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

        if(self.path == "/synchronise/schedules"):
            self.synchroniseSchedules(message)
            return
        elif(self.path == "/synchronise/schedule"):
            self.synchroniseSchedule(message)
            return
        elif(self.path == "/keysubmit"):
            self.addKey(message)
            return
        else:
            print("hmmm...")

        print(f"Received POST data: {post_data.decode('utf-8')}")
        
        self.send_response(400)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        response_message = (b"POST request received successfully! But sent to unknown path: ",self.path)
        self.wfile.write(response_message)
    def synchroniseSchedules(self, schJsons):
        global keysLock, fileLock, schedules
        print("Received synchronisation POST request")
        schList = schJsons.split("\r\n\r\n")

        #overwrite all schedules
        fileLock.acquire_lock()
        schFile = open(scheduleFileDir,"w")
        schFile.write(schJsons)
        schFile.close()
        fileLock.release_lock()

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
            schedule.saveToFile()
            print(schedule.toJson())

            updateForExistingSchedule = False
            print("                     --"+threading.current_thread().name+": WAITING schedulesLock")
            schedulesLock.acquire_lock()
            print("                     --"+threading.current_thread().name+": ACQUIRED schedulesLock")
            for i in range(len(schedules)):
                if schedule.scheduleUUID == schedules[i].scheduleUUID:
                    schedules[i] = schedule
                    updateForExistingSchedule = True
                    break
            if not updateForExistingSchedule:
                schedules.append(schedule)
            schedulesLock.release_lock()
            print("                     --"+threading.current_thread().name+": RELEASED schedulesLock")
        except Exception as e:
            print("     FAILED to decode json:",e)  
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
        print(connectionProgressPadding+n.ssid)
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
    global received_keys, computerLocked, lockedUntilNextQuestCompletionOREOD, schedules, keysLock, connected, schedulesLock
    try:
        print("Locking during init...")
        screen_off()
        computerLocked = True
        print("==========================================================================================================COMPUTER LOCKED==========================================================================================================")

        print("Starting program")
        schedules = Schedule.readListFromFile(scheduleFileDir)
        if schedules == None:
            print("FAILED TO LOAD")
            screen_on()
            return
        
        serverThread = threading.Thread(target=hostServer)
        serverThread.start()

        connectionThread = threading.Thread(target=pollConnection)
        connectionThread.start()
    except Exception as e:
        print(e)
        screen_on()
        return
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
                    scheduleEndKey = schedule.scheduleUUID  
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
            screen_off()
            computerLocked = True
        else:
            print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++COMPUTER UNLOCKED++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            screen_on()
            computerLocked = False
        time.sleep(5)

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
#       IF SCHEDULEUUID+BOOL JSON RECEIVED, ADD TO RECEIVED_KEYS


#CHANGES TO BE MADE TO IOS APP: SCHEDULE'S SHOULD TRACK VIA BOOL IF THEY ARE SYNCHRONISED WITH THE PC LOCK SERVER OR NOT
#   UPON CHANGES, BOOL "SYNCHRONISED" = FALSE
#   WHILE SYNCHRONISED == FALSE -> ATTEMPT HTTP POST REQUEST, IF RESPONSE RECEIVED (200) THEN MARK AS TRUE
#   UNSYNCHRONISED SCHEDULES CAN STILL START WITH THEIR NEW SCHEDULE STUFF


#main()