#import webStuff
#import random
#import os
#import keyboard, mouse
import threading
#import pywhatkit
import time
#import win32gui
#import pygetwindow as gw 
#from pywhatkit.core import core
#import webbrowser as web
#import pyautogui

import ThreadUtils
import ComputerControl
import time
import pygetwindow as gw
from datetime import datetime, timedelta
import json
import subprocess
#import re
from winwifi import WinWiFi
from DeadMansSwitch import DeadmansSwitch
from http.server import HTTPServer, SimpleHTTPRequestHandler


# SERVER STUFF ---------------------------------------------------------------------------------------------
global received_keys, computerLocked, lockedUntilNextQuestCompletionOREOD, schedules, keysLock, connected, PQ_Server, deadmansSwitch, questLock
#schedules defined after Schedule class def
deadmansSwitch = DeadmansSwitch()
received_keys: list[str] = []
computerLocked = False
lockedUntilNextQuestCompletionOREOD = False
keysLock = threading.Lock() 
schedulesLock = threading.Lock()
questLock = threading.Lock()
fileLock = threading.Lock()
scheduleFileDir = "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/schedules.txt"
questFileDir = "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/activequests.txt"
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

class Quest:
    def __init__(self, jsonQ):
        data = json.loads(jsonQ)
        self.questUUID = data['questUUID']
        self.isActive = True
    
    def toJson(self):
        string = "{\n\"questUUID\" : \""+ self.questUUID.__str__()+"\"\n}"
        return string

    def saveToFile(self):
        global fileLock

        ThreadUtils.acquireLock(fileLock, "File Lock")
        # if adding a quest (quest only exists/is active when expecting a key and only saves to file when creating/deleting
        if self.isActive:
            writtenQuests = open(questFileDir, "a")
            writtenQuests.write(self.toJson()+"\n")
            writtenQuests.close()
        else:
            writtenQuests = open(questFileDir, "r")
            lines = writtenQuests.readlines()
            writtenQuests.close()
            #only write the non-this-uuid ones back
            writtenQuests = open(questFileDir, "w")
            for line in lines:
                if self.questUUID not in line:
                    writtenQuests.write(line+"\n")
            writtenQuests.close()
        ThreadUtils.releaseLock(fileLock, "File Lock")

class Schedule:
    #isActive: bool
    #questInProgress: bool
    #startTime: datetime
    #scheduledEndTime: datetime
    #scheduledStartTime: datetime
    #scheduleName: str
    #questUUID: str
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
        self.questUUID = str(data['questUUID'])

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

        #stored with each schedule json split up by double line breaks
        writtenSchedules = Schedule.readListFromFile(scheduleFileDir)
        ThreadUtils.acquireLock(fileLock, "File Lock")
        schFile = open(scheduleFileDir, "w")

        #see if updating existing schedule
        updateForExistingSchedule = False
        i = 0
        for sch in writtenSchedules:
            if self.questUUID == sch.questUUID:
                writtenSchedules[i] = self
                updateForExistingSchedule = True
                break
            i+=1
        if not updateForExistingSchedule:
            writtenSchedules.append(self)
        
        #re-write all schedules back in to file
        i = 0
        totalStr = ""
        for i in range(0,len(writtenSchedules)):
            totalStr += writtenSchedules[i].toJson()
            if i < writtenSchedules.__len__()-1:
                totalStr += "\n\n"
        schFile.write(totalStr)
        schFile.close()
        ThreadUtils.releaseLock(fileLock, "File Lock")
 
    def endQuest(self):
        self.questInProgress = False
        self.updateStartTime()

    def toJson(self):
        #should be formatted { "isActive" : "True", "questInProgress" : "False", "schedule_everyXDays" : "False", "scheduleName" : "Scheduled New Quest", "questUUID" : "FE61BBA7-2D07-4BBF-B335-1FF8DD12EB2B", "schedule_XDayDelay" : "1", "startTime" : "06/01/2026, 11:09:00", "scheduledStartTime" : "06/01/2026, 11:09:00", "scheduledEndTime" : "06/01/2026, 20:00:00", "schedule_lastCompletionTime" : "05/01/2026, 19:16:45", "schedule_scheduledDays" : "1111111" }
        string = "{\n"
        string += "\"isActive\" : \""+self.isActive.__str__()+"\",\n"
        string += "\"questInProgress\" : \""+self.questInProgress.__str__()+"\",\n"
        string += "\"schedule_everyXDays\" : \""+self.scheduleInfo_everyXDays.__str__()+"\",\n"
        string += "\"scheduleName\" : \""+ self.scheduleName.__str__()+"\",\n"
        string += "\"questUUID\" : \""+ self.questUUID.__str__()+"\",\n"
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
            if content == '':
                fileLock.release_lock()
                return []
            #in file, schedules are separated by double line breaks
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
            fileLock.release_lock()
            return []
        
        fileLock.release_lock()
        return schList
    
    def tryStarting(self) -> Quest:
        actualEndTime = self.startTime + (self.scheduledEndTime - self.scheduledStartTime)

        print("Checking if "+self.scheduleName+" should have started ("+self.startTime.__str__()+" - "+actualEndTime.__str__()+")")
        if self.startTime <= datetime.now():
            print("Starting",self.scheduleName+"'s quest lockdown\n")
            self.questInProgress = True
            self.saveToFile()
            return Quest("{\n\"questUUID\":\""+self.questUUID.__str__()+"\"\n}")
        else:
            print("Not time.\n")
            return None

schedules: list[Schedule] = []
activeQuests: list[Quest] = []
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
        elif(self.path == "/synchronise/startQuest"):
            self.startQuest(message)
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
        ThreadUtils.acquireLock(fileLock, "File Lock")
        schFile = open(scheduleFileDir,"w")
        schFile.write(schJsons.replace("\r\n\r\n","\n\n"))
        schFile.close()
        ThreadUtils.releaseLock(fileLock, "File Lock")

        #overwrite global schedules list
        try:
            print("Synchronising....") 
            ThreadUtils.acquireLock(schedulesLock, "Schedules Lock")
            schedules = []
            for sch in schList:
                schedule = Schedule(sch)
                print(schedule.toJson())
                schedules.append(schedule)
        except Exception as e:
            print("ERROR SYNCHRONISING",e)

        ThreadUtils.releaseLock(schedulesLock, "Schedules Lock")
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
                if schedule.questUUID == schedules[i].questUUID:
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

    def startQuest(self, quest):
        global questLock

        data = json.load(quest)

        q = Quest(data)
        q.saveToFile()
        
        ThreadUtils.acquireLock(questLock, "Quest Lock")
        activeQuests.append(q)
        ThreadUtils.releaseLock(questLock, "Quest Lock")

    def addKey(self, reward):
        global keysLock, received_keys
        print("appending to keys")

        data = json.load(reward)
        key = data['questUUID'] + "_" + boolFromJson(data['completedOnTime'])

        ThreadUtils.acquireLock(keysLock, "Key Lock")
        received_keys.append(key)
        ThreadUtils.releaseLock(keysLock, "Key Lock")
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

def checkForKey(schedule: Schedule) -> bool:
    global received_keys, keysLock
    keyFound = False

    #try ending active scheduled quest, no need to check if no schedule end keys have been received
    if len(received_keys) > 0:
        #if active, may be pending on key to end
        scheduleEndKey = schedule.questUUID  
        ThreadUtils.acquireLock(keysLock, "Keys Lock")
        for key in received_keys:
            if scheduleEndKey in key:
                keyFound = True
                finishedOnTime = key.split('_')[1]
                print("Key received for "+schedule.scheduleName)
                if finishedOnTime == "True":
                    print(schedule.scheduleName + " completed on time!\n")
                    break
                else:
                    print(schedule.scheduleName + " failed.\n")
                    break
        ThreadUtils.releaseLock(keysLock, "Keys Lock")
    else:
        print("No keys received\n")
    
    if keyFound:
        schedule.endQuest()
        schedule.saveToFile()
    return keyFound

def checkForKey(quest: Quest) -> bool:
    global received_keys, keysLock
    keyFound = False

    #try ending active scheduled quest, no need to check if no schedule end keys have been received
    if len(received_keys) > 0:
        #if active, may be pending on key to end
        questEndKey = quest.questUUID
        for key in received_keys:
            if questEndKey in key:
                keyFound = True
                finishedOnTime = key.split('_')[1]
                print("Quest Key Received")
                if finishedOnTime == "True":
                    print("Quest Complete!\n")
                    break
                else:
                    print("Quest Failed.\n")
                    break
    else:
        print("No keys received\n")
    
    if keyFound:
        quest.isActive = False
        quest.saveToFile()
    return keyFound

def controlLoop():
    global keysLock, schedulesLock, questLock
    while(True):

        questsInProgress = False

        #check if key received to end progress of quest
        #check if quest scheduled to start
        ThreadUtils.acquireLock(keysLock, "Keys Lock")
        ThreadUtils.acquireLock(schedulesLock, "Schedules Lock")
        global schedules
        for schedule in schedules:
            print("Inspecting "+schedule.scheduleName)
            #if quest currently active 
            #   -> key received? endQuest()
            #   -> not received? questsInProgress = True
            if schedule.questInProgress:
                #if quest in progress then the only thing the pc should be doing is trying to allow the user to unlock the pc
                global connected, attemptingConnection
                if not connected and not attemptingConnection:
                    #connecting to the network will make the hostServer thread start attempting to host the server
                    threading.Thread(target=connectToPrivateNetwork).start()
                    
                #if no key provided, quest still in progress and lockdown still in effect
                if not checkForKey(schedule):
                    questsInProgress = True

            #if scheduled quest inactive, see if it needs to start
            elif schedule.isActive:
                quest = schedule.tryStarting()

                if quest != None:
                    questsInProgress = True
            else:
                print(schedule.scheduleName, "not active\n")
        ThreadUtils.releaseLock(schedulesLock, "Schedules Lock")
        
        ThreadUtils.acquireLock(questLock, "Quest Lock")
        global activeQuests
        for quest in activeQuests:
            if not checkForKey(quest):
                questsInProgress = True

        delCount = 0
        for i in range(len(activeQuests)):
            if not activeQuests[i - delCount].isActive:
                activeQuests.remove(activeQuests[i - delCount])
                delCount+=1
                continue
        ThreadUtils.releaseLock(questLock, "Quest Lock")

        #all keys have been checked and used, so clear them
        global received_keys
        received_keys = []
        ThreadUtils.releaseLock(keysLock, "Keys Lock")

        #check computer lock status
        global computerLocked
        if (questsInProgress):
            print("===========================================================================================================COMPUTER LOCKED===========================================================================================================")
            #ComputerControl.blockInput()
            computerLocked = True
            win = gw.getWindowsWithTitle('C:\\Program Files\\WindowsApps\\PythonSoftwareFoundation.Python.3.11_3.11.2544.0_x64__qbz5n2kfra8p0\\python3.11.exe')[0] 
            win.activate()
        else:
            print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++COMPUTER UNLOCKED++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            ComputerControl.unblockInput()
            computerLocked = False
        time.sleep(5)

def newMain():
    global computerLocked, schedules, connected, schedulesLock, deadmansSwitch, questLock, activeQuests, keysLock
    try:
        print("Locking during init...") 
        ComputerControl.blockInput()
        print("==========================================================================================================COMPUTER LOCKED==========================================================================================================")

        #---Create a deadmans switch
        #create another process that checks for pings to tcp://localhost:1617
        print("Creating deadmans switch")
        deadmansSwitch.createSwitch() #can be stopped via deadmansSwitch.stop() (hopefully)
        #create a thread that sends pings to ttcp://localhost:1617
        print("Holding deadmans switch")
        deadmanThread = threading.Thread(target=DeadmansSwitch.deadmansHold)
        deadmanThread.start()
        #if this program gets ended, the pings stop sending and switch is 'released', causing a PC shutdown

        print("loading schedules")
        schedules = Schedule.readListFromFile(scheduleFileDir)

        print("creating server thread")
        serverThread = threading.Thread(target=hostServer)
        serverThread.start()

        print("creating phone connection poller")
        connectionThread = threading.Thread(target=pollConnection)
        connectionThread.start()

        print("Init finished... Unlocking and starting now")
        ComputerControl.unblockInput()
        
        controlLoop()

    except Exception as e:
        deadmansSwitch.stopSwitch()
        print(e)
        ComputerControl.unblockInput()
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