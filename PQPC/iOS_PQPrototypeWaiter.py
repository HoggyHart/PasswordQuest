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
from DeadMansSwitch import DeadmansSwitch
from http.server import HTTPServer, SimpleHTTPRequestHandler
import WifiUtils
import socket
from PQCONSTS import PQLOG, SCHFLDIR, QSTFLDIR, DEBUGMODE, SHUTDOWNDELAY

class utils:
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
        try:
            data = json.loads(jsonQ)
            self.questUUID = data['questUUID']
            self.isActive = True
        except Exception as e:
            #PQLog.debug("Failed to load quest!")
            raise e
    
    def toJson(self):
        string = "{\n\"questUUID\" : \""+ self.questUUID.__str__()+"\"\n}"
        return string 

class Schedule:
    def __init__(self, jsonSch):
        #decode from json
        data = json.loads(jsonSch)
        #simple bools
        self.isActive = utils.boolFromJson(data['isActive'])
        self.questInProgress = utils.boolFromJson(data['questInProgress'])
        self.scheduleInfo_everyXDays = utils.boolFromJson(data['schedule_everyXDays'])
        
        #simple string
        self.scheduleName = str(data['scheduleName'])
        self.questUUID = str(data['questUUID'])

        #int
        self.scheduleInfo_XDayDelay = int(data['schedule_XDayDelay'])

        #dates (formatted "dd-mm-yyyy hh:mm::ss" )
        self.startTime = utils.dateFromJson(str(data['startTime']))
        self.scheduledStartTime = utils.dateFromJson(str(data['scheduledStartTime']))
        self.scheduledEndTime = utils.dateFromJson(str(data['scheduledEndTime']))
        self.scheduleInfo_lastCompletionTime = utils.dateFromJson(str(data['schedule_lastCompletionTime']))

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
        gap = -999
        for i in range(0,7):
            #if day scheduled and first scheduled day found
            if self.scheduleInfo_ScheduledDays[i]==True:
                gap = i - curDayOfWeek

            if self.scheduleInfo_ScheduledDays[i]==True and i > curDayOfWeek:
                gap = i - curDayOfWeek
                break
            
        if gap == -999:
            self.isActive = False
            return fromDate
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
        string += "\"startTime\" : \""+utils.dateToJson(self.startTime)+"\",\n"
        string += "\"scheduledStartTime\" : \""+utils.dateToJson(self.scheduledStartTime)+"\",\n"
        string += "\"scheduledEndTime\" : \""+utils.dateToJson(self.scheduledEndTime)+"\",\n"
        string += "\"schedule_lastCompletionTime\" : \""+utils.dateToJson(self.scheduleInfo_lastCompletionTime)+"\",\n"
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
    
    def tryStarting(self) -> Quest:
        actualEndTime = self.startTime + (self.scheduledEndTime - self.scheduledStartTime)

        #PQLog.debug("    Starts at "+self.startTime.__str__())
        PQLOG.debug("Checking if "+self.scheduleName+" should have started ("+self.startTime.__str__()+" - "+actualEndTime.__str__()+")")

        if self.startTime <= datetime.now():
            PQLOG.debug("    Starting " + self.scheduleName)
            self.questInProgress = True
            return Quest("{\n\"questUUID\":\""+self.questUUID.__str__()+"\"\n}")
        else:
            PQLOG.debug("    Not time.")
            return None

class PQRequestHandler(SimpleHTTPRequestHandler):
    
    def do_GET(self):
        self.mainProgram: PasswordQuestServer = self.server.mainProgram
        self.mainProgram.pingCounter+=1
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(bytes("wazzup"))

    def do_POST(self):
        self.mainProgram: PasswordQuestServer = self.server.mainProgram
        global PQLOG
        PQLOG.debug("Received data for " +self.path)
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        message = post_data.decode('utf-8')
        PQLOG.debug("Received: \n"+ repr(message))
        message = message.replace('\r','')      

        if(self.path == "/synchronise/schedules"):
            self.synchroniseSchedules(message)
            return
        elif(self.path == "/synchronise/schedule"):
            self.synchroniseSchedule(message)
            return
        elif(self.path == "/synchronise/activequest"):
            self.startQuest(message)
            return
        elif(self.path == "/redeem"):
            self.addKey(message)
            return
        else:
            self.send_response(404)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        response_message = f"POST request received successfully! But sent to unknown path: {self.path}"
        self.wfile.write(bytes(response_message))

    def synchroniseSchedules(self, schJsons: str):
        global PQLOG
        self.mainProgram.syncLock = False
        PQLOG.debug("Releasing SyncLock")
        #post load comes in split by \r\n\r\n
        schList = schJsons.split("\n\n")
        PQLOG.debug("Received schedules:")
        for s in schList:
            PQLOG.debug("Received:\n"+repr(s))

        #overwrite all schedules
        self.mainProgram.threadUtil.acquireLock("FileLock")
        schFile = open(SCHFLDIR,"w")
        schFile.write(schJsons)
        schFile.close()
        self.mainProgram.threadUtil.releaseLock("FileLock")

        #overwrite global PQLog, schedules list
        try:
            PQLOG.debug("Synchronising...") 
            self.mainProgram.threadUtil.acquireLock("ScheduleLock")
            self.mainProgram.schedules = []
            for sch in schList:
                schedule = Schedule(sch)
                PQLOG.debug("==========LOADED==========\n"+schedule.toJson()+"\n==========================\n")
                self.mainProgram.schedules.append(schedule)
                PQLOG.debug("saved to list")
            PQLOG.debug("finished saving schedule changes")
            self.send_response(200)
        except Exception as e:
            #PQLog.debug("Synchronisation failed!")
            PQLOG.critical("ERROR SYNCHRONISING "+str(e))
            try:
                self.send_response(500)
            except:
                PQLOG.critical(str(e))
        self.mainProgram.threadUtil.releaseLock("ScheduleLock")
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

    def synchroniseSchedule(self, schJson):
        global PQLOG
        try:
            schedule = Schedule(schJson)
            self.mainProgram.saveScheduleToFile(schedule)
            PQLOG.debug(schedule.toJson())

            updateForExistingSchedule = False
            self.mainProgram.threadUtil.acquireLock("ScheduleLock")
            for i in range(len(self.mainProgram.schedules)):
                if schedule.questUUID == self.mainProgram.schedules[i].questUUID:
                    self.mainProgram.schedules[i] = schedule
                    updateForExistingSchedule = True
                    break
            if not updateForExistingSchedule:
                self.mainProgram.schedules.append(schedule)
        except Exception as e:
            PQLOG.debug("     FAILED to decode json: "+e)  
        
        self.mainProgram.threadUtil.releaseLock("ScheduleLock")

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

    def startQuest(self, quest):
        global PQLOG

        q = Quest(quest)
        self.mainProgram.saveQuestToFile(q)
        
        self.mainProgram.threadUtil.acquireLock("QuestLock")
        PQLOG.debug("Added key for some active quest")
        self.mainProgram.activeQuests.append(q)
        self.mainProgram.threadUtil.releaseLock("QuestLock")

    def addKey(self, reward):
        PQLOG.debug("appending to keys")
        data = json.loads(reward)
        key = data['questUUID'] + "_" + data['completedOnTime']

        self.mainProgram.threadUtil.acquireLock("KeyLock")
        self.mainProgram.receivedKeys.append(key)
        self.mainProgram.threadUtil.releaseLock("KeyLock")
        PQLOG.debug("finished appending to keys")
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

class PQHTTPServer(HTTPServer):
    def __init__(self, address, handler, prog):
        super().__init__(address, handler)
        self.mainProgram = prog
        

class PasswordQuestServer:

    ### HTTP Server stuff

###
    def connectToPrivateNetwork(self):
        global PQLOG
        self.attemptingNetworkConnection = True
        
        network_SSID = "WillPhone"
        network_Password = "poopoo1!"
        
        PQLOG.debug(f"Attempting to connect to {network_SSID}...")
        self.connectedToNetwork = WifiUtils.connect_to_wifi(network_SSID,network_Password)
        if self.connectedToNetwork:
            PQLOG.debug("++++Success++++")
        else:
            PQLOG.debug("----Failure----")

        self.attemptingNetworkConnection = False

    def pollConnection(self):
        global PQLOG
        while(True):
            try:
                PQLOG.debug("Scanning networks...")
                wifi = subprocess.check_output(['netsh', 'WLAN', 'show', 'interfaces'], creationflags=subprocess.CREATE_NO_WINDOW)
            except Exception as e:
                PQLOG.debug("Failed to scan networks")
                self.connectedToNetwork = False
                PQLOG.critical(str(e))
                time.sleep(5)
                continue
            data = wifi.decode('utf-8')
            if "WillPhone" in data:
                PQLOG.debug("Result: Connected to QuestNetwork")
                self.connectedToNetwork = True
            else:
                PQLOG.debug("Result: Not connected to QuestNetwork")
                try:
                    PQLOG.debug("Attempting to shut down server")
                    self.PQ_Server.shutdown()
                except Exception as e:
                    PQLOG.debug("No server to shut down")
                self.connectedToNetwork= False
            time.sleep(5)

    def hostServer(self):
        global PQLOG
        while(True):
            if self.connectedToNetwork:
                PQLOG.debug("Attempting host")
                try:
                    self.PQ_Server = PQHTTPServer(('172.20.10.5', 1617), PQRequestHandler,self)
                    PQLOG.debug("Server created!")
                    self.PQ_Server.serve_forever()
                except Exception as e:
                    PQLOG.critical("Failed to continue hosting server, trying again in 5 seconds...")
                    PQLOG.critical(str(e))
                    time.sleep(5)
            #should only NOT be connected if there is no need or want to be.
            #quest is active -> connectToPrivateNetwork() gets called until connected = true
            #user wants to synchronise schedules -> manual connection -> this else: code checks if its connnected -> connected = true (if it is)
            else:
                PQLOG.debug("Not connected to Quest Network, retrying host in 3 seconds")
                time.sleep(3)

    def run(self):
        global PQLOG

        #safety ping to notify starter program that it has started
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(b"alive", ("127.0.0.1", 1617))
        sock.close()

        self.pingCounter = 0
        try:
            self.threadUtil = ThreadUtils.ThreadUtility()

            #base data
            self.schedules: list[Schedule] = []
            self.activeQuests: list[Quest] = []
            self.receivedKeys: list[str] = []

            #phone-link data
            self.connectedToNetwork = False
            self.attemptingNetworkConnection = False

            #anti-cheat
            self.deadmansSwitch = DeadmansSwitch()
            self.syncLock = True

            #setting up threads
            PQLOG.debug("Locking during init")
            if not DEBUGMODE:{ComputerControl.blockInput()}

            #---Create a deadmans switch that shuts down computer if either this program or the switch program is closed
            PQLOG.debug("Creating deadmans switch two-way")
            self.deadmansThread = self.deadmansSwitch.createTwoWaySwitchV2("PasswordQuest.py",SHUTDOWNDELAY)
            self.deadmansThread.start()

            PQLOG.debug("loading schedules")
            self.schedules = self.loadSchedules(SCHFLDIR)

            PQLOG.debug("Loading active quests")
            self.activeQuests = self.loadQuests(QSTFLDIR)

            PQLOG.debug("creating server thread")
            serverThread = threading.Thread(target=self.hostServer)
            serverThread.start()

            PQLOG.debug("creating phone connection poller")
            connectionThread = threading.Thread(target=self.pollConnection)
            connectionThread.start()

            PQLOG.debug("Init finished... Unlocking and starting now")
            ComputerControl.unblockInput()
            
            self.controlLoop()

        except Exception as e:
            PQLOG.debug("Main loop escaped!")

            #external program stops sending/receiving || this means the thread in this program will timeout and shut down pc
        # deadmansSwitch.stopSwitch()
            self.deadmansSwitch.stopAllSwitches()
            PQLOG.debug(f"{e}")
            ComputerControl.unblockInput()

    def checkForSchKey(self, schedule: Schedule) -> bool:
        global PQLOG
        keyFound = False

        #try ending active scheduled quest, no need to check if no schedule end keys have been received
        if len(self.receivedKeys) > 0:
            #if active, may be pending on key to end
            scheduleEndKey = schedule.questUUID  
            for key in self.receivedKeys:
                if scheduleEndKey in key:
                    keyFound = True
                    finishedOnTime = key.split('_')[1]
                    if finishedOnTime == "True":
                        PQLOG.debug("   "+schedule.scheduleName + " completed on time!")
                        break
                    else:
                        PQLOG.debug("   "+schedule.scheduleName + " failed.")
                        break
        
        if keyFound:
            schedule.endQuest()
            schedule.saveToFile()
        return keyFound

    def checkForQKey(self, quest: Quest) -> bool:
        global PQLOG
        keyFound = False

        #try ending active scheduled quest, no need to check if no schedule end keys have been received
        if len(self.receivedKeys) > 0:
            #if active, may be pending on key to end
            questEndKey = quest.questUUID
            for key in self.receivedKeys:
                if questEndKey in key:
                    keyFound = True
                    finishedOnTime = key.split('_')[1]
                    if finishedOnTime == "True":
                        PQLOG.debug("   Quest Complete!")
                        break
                    else:
                        PQLOG.debug("   Quest Failed.")
                        break
        if keyFound:
            quest.isActive = False
            self.saveQuestToFile(quest)
        else:
            PQLOG.debug("   Key not found.")
        return keyFound
    def saveScheduleToFile(self, schedule: Schedule):
        global PQLOG
        #stored with each schedule json split up by double line breaks
        writtenSchedules = self.loadSchedules(SCHFLDIR)
        self.threadUtil.acquireLock("FileLock")
        schFile = open(SCHFLDIR, "w")

        #see if updating existing schedule
        updateForExistingSchedule = False
        i = 0
        for sch in writtenSchedules:
            if schedule.questUUID == sch.questUUID:
                writtenSchedules[i] = schedule
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
        self.threadUtil.releaseLock("FileLock")
    def saveQuestToFile(self, quest: Quest):
        global PQLOG

        self.threadUtil.acquireLock("FileLock")
        # if adding a quest (quest only exists/is active when expecting a key and only saves to file when creating/deleting
        if quest.isActive:
            writtenQuests = open(QSTFLDIR, "a")
            writtenQuests.write("\n"+quest.toJson()+"\n")
            writtenQuests.close()
        else:
            writtenQuests = open(QSTFLDIR, "r")
            quests = writtenQuests.read().split("\n\n")
            writtenQuests.close()
            #only write the non-this-uuid ones back
            writtenQuests = open(QSTFLDIR, "w")
            for q in quests:
                if quest.questUUID not in q:
                    writtenQuests.write("\n"+q+"\n")
            writtenQuests.close()
        self.threadUtil.releaseLock("FileLock")  
    def controlLoop(self):
        global PQLOG

        while(True):
            questsInProgress = False

            #check if key received to end progress of quest
            self.threadUtil.acquireLock("KeyLock")
            keylist = ""
            for key in self.receivedKeys:
                keylist+="  -> "+key+"\n"
            PQLOG.debug("Current keys:\n"+keylist)
            self.threadUtil.acquireLock("QuestLock")
            #if quests are active, attempt to connect to network

            #check for keys
            PQLOG.debug(f'Checking keys for {len(self.activeQuests)} active quests')
            for quest in self.activeQuests:
                if not self.checkForQKey(quest):
                    questsInProgress = True
            #PQLog.debug()

            #remove now-inactive quests
            delCount = 0
            for i in range(len(self.activeQuests)):
                if not self.activeQuests[i - delCount].isActive:
                    self.activeQuests.remove(self.activeQuests[i - delCount])
                    delCount+=1
            self.threadUtil.releaseLock("QuestLock")

            #check if quest scheduled to start
            self.threadUtil.acquireLock("ScheduleLock")
            for schedule in self.schedules:
                PQLOG.debug(schedule.scheduleName)
                #if quest currently active 
                #   -> key received? endQuest()
                #   -> not received? questsInProgress = True
                if schedule.questInProgress:
                    PQLOG.debug(f"    In progress.")
                    #if no key provided, quest still in progress and lockdown still in effect
                    if not self.checkForSchKey(schedule):
                        questsInProgress = True

                #if scheduled quest inactive, see if it needs to start
                elif schedule.isActive:
                    quest = schedule.tryStarting()

                    if quest != None:
                        self.saveScheduleToFile(schedule)
                        questsInProgress = True
                else:
                    PQLOG.debug("----Not active.")
            #PQLog.debug()
            self.threadUtil.releaseLock("ScheduleLock")

            #all keys have been checked and used, so clear them
            self.receivedKeys = []
            self.threadUtil.releaseLock("KeyLock")

            #check computer lock status
            if (questsInProgress or self.syncLock):
                PQLOG.debug(f"Quests in progress: {questsInProgress} | SyncLock active: {self.syncLock}")
                PQLOG.debug("=====================================================COMPUTER LOCKED=====================================================")
                #if quest in progress then the only thing the pc should be doing is trying to allow the user to unlock the pc
                PQLOG.debug("connected: "+str(self.connectedToNetwork)+" | attempting connection: "+str(self.attemptingNetworkConnection))
                if not self.connectedToNetwork and not self.attemptingNetworkConnection:
                    #connecting to the network will make the hostServer thread start attempting to host the server
                    threading.Thread(target=self.connectToPrivateNetwork).start()
                if not DEBUGMODE:{ComputerControl.blockInput()}
                self.computerLocked = True
                try:
                    win: gw.Win32Window = gw.getWindowsWithTitle('PasswordQuest')[0]         
                    win.minimize()
                    win.maximize()
                except Exception as e:
                    PQLOG.debug("Failed to bring window to front"+str(e))
            else:
                PQLOG.debug("++++++++++++++++++++++++++++++++++++++++++++++++++++COMPUTER UNLOCKED++++++++++++++++++++++++++++++++++++++++++++++++++++")
                ComputerControl.unblockInput()
                self.computerLocked = False
            time.sleep(5)

    def loadSchedules(self, schDir):
        global PQLOG
        schList: list[Schedule] = []
        try:
            self.threadUtil.acquireLock("FileLock")
            schFile = open(schDir,"r")
            content = schFile.read()
            PQLOG.debug("RAW FILE DATA:\n" + repr(content))
            if content == '':
                raise Exception("No Data Found In File")
            #in file, schedules are separated by double line breaks
            schs = content.split("\n\n")
            for sch in schs:
                schList.append(Schedule(sch))
                PQLOG.debug("LOADED:\n" + repr(sch) + "\nAS\n" + schList[-1].toJson())
            schFile.close()
        except Exception as e:
            PQLOG.critical(str(e))
        
        self.threadUtil.releaseLock("FileLock")
        return schList

    def loadQuests(self, qstDir):
        global PQLOG
        qstList: list[Quest] = []
        try:
            self.threadUtil.acquireLock("FileLock")
            qstFile = open(qstDir,"r")
            content = qstFile.read()
            PQLOG.debug("RAW FILE DATA:\n" + repr(content))
            if content == '':
                raise Exception("No Data Found In File")
            #in file, quests are separated by double line breaks
            qsts = content.split("\n\n")
            for q in qsts:
                qstList.append(Quest(q))
                PQLOG.debug("LOADED:\n" + repr(q) + "\nAS\n" + qstList[-1].toJson())
            qstFile.close()
        except Exception as e:
            PQLOG.critical(str(e))
        
        self.threadUtil.releaseLock("FileLock")
        return qstList

if __name__ == "__main__":
    pq = PasswordQuestServer()
    try:
        pq.run()
    except Exception as e:
        print(str(e))

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