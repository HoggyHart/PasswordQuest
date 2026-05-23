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

from datetime import datetime, timedelta
import json
import subprocess
from DeadMansSwitch import DeadmansSwitch
from http.server import HTTPServer, SimpleHTTPRequestHandler
import WifiUtils
import socket
import sys
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
        

class Quest:
    def __init__(self, name, uuid, expiryDate, scheduler = "0"):
        self.name = name
        self.questUUID = uuid
        self.expiryDate = expiryDate
        self.scheduler = scheduler
        self.isActive = True
    
    def __repr__(self):
        return self.toJson().__str__()

    def toJson(self):
        string = {
            'questName':self.name,
            'questUUID':self.questUUID,
            'expiryDate':utils.dateToJson(self.expiryDate),
            'scheduler':self.scheduler
            }
        return string 

    def fromJson(data):
        return Quest(data['questName'],data['questUUID'],utils.dateFromJson(data['expiryDate']))

class Schedule:
   
    def __init__(self, schName, active, quest: Quest, startTime, endTime, schedulePattern, xdayDelay, scheduledDays, scheduleUUID):
        self.scheduleName = schName
        self.isActive = active
        self.quest = quest
        self.scheduledStartTime = startTime
        self.scheduledEndTime = endTime
        self.scheduleInfo_everyXDays = schedulePattern
        self.scheduleInfo_XDayDelay = xdayDelay
        self.scheduleInfo_ScheduledDays = str(scheduledDays)
        self.scheduleUUID = scheduleUUID
    
    def getNext_XDayDelay_StartTime(self, fromDate: datetime) -> datetime:
        return fromDate + timedelta(days=self.scheduleInfo_XDayDelay)

    def getNext_ScheduledDays_StartTime(self, fromDate: datetime) -> datetime:
        curDayOfWeek = fromDate.weekday()+1
        if curDayOfWeek == 7: #wrapping to fit iOS Swift's 0 = Sunday, 1 = Monday pattern
            curDayOfWeek = 0

        gap = -999
        for i in range(0,7):
            #if day scheduled and first scheduled day found
            if self.scheduleInfo_ScheduledDays[i]=="1" and gap == -999:
                gap = i - curDayOfWeek

            if self.scheduleInfo_ScheduledDays[i]=="1" and i > curDayOfWeek:
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

        if self.scheduleInfo_everyXDays:
            self.scheduledStartTime = self.getNext_XDayDelay_StartTime(self.scheduledStartTime)
        else:
            self.scheduledStartTime = self.getNext_ScheduledDays_StartTime(self.scheduledStartTime)
                                                   
        self.scheduledEndTime = self.scheduledStartTime + dur
    def __repr__(self):
        return self.toJson().__str__()
    def toJson(self):
        data = {
            'scheduleName': self.scheduleName,
            'isActive': self.isActive,
            'quest': self.quest.toJson(),
            'schedule_everyXDays': self.scheduleInfo_everyXDays,
            'schedule_XDayDelay': self.scheduleInfo_XDayDelay,
            'scheduledStartTime': utils.dateToJson(self.scheduledStartTime),
            'scheduledEndTime': utils.dateToJson(self.scheduledEndTime),
            'schedule_scheduledDays': str(self.scheduleInfo_ScheduledDays),
            'scheduleUUID': self.scheduleUUID
        }
        return data    
    def fromJson(data):
        return Schedule(
            data['scheduleName'],
            data['isActive'],
            Quest.fromJson(data['quest']),
            utils.dateFromJson(data['scheduledStartTime']),
            utils.dateFromJson(data['scheduledEndTime']),
            data['schedule_everyXDays'],
            int(data['schedule_XDayDelay']),
            data['schedule_scheduledDays'],
            data['scheduleUUID']
            )
    
    def tryStarting(self) -> Quest:

        if self.scheduledStartTime <= datetime.now():
            self.updateStartTime()
            return Quest(self.quest.name,self.quest.questUUID,self.scheduledEndTime,self.scheduleUUID)
        else:
            return None

class PQRequestHandler(SimpleHTTPRequestHandler):
    
    def do_GET(self):
        try:
            self.mainProgram: PasswordQuestServer = self.server.mainProgram
            self.mainProgram.pingCounter+=1
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(bytes("GOT",'utf-8'))
        except Exception as e:
            PQLOG.critical(str(e))

    def do_POST(self):
        self.mainProgram: PasswordQuestServer = self.server.mainProgram
        global PQLOG
        PQLOG.debug("Received data for " +self.path)
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        message = post_data.decode('utf-8')
        PQLOG.debug("Received: \n"+ repr(message))
        print(repr(message)) 

        if(self.path == "/synchronise/schedules"):
            self.synchroniseSchedules(message)
            return
       # elif(self.path == "/synchronise/schedule"):
            #self.synchroniseSchedule(message)
           # return
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
        self.wfile.write(bytes(response_message,'utf-8'))

    def synchroniseSchedules(self, schJsons):
        global PQLOG
        self.mainProgram.syncLock = False
        schJsons = json.loads(schJsons)
        #overwrite global PQLog, schedules list
        self.mainProgram.threadUtil.acquireLock("ScheduleLock")
        try:
            self.mainProgram.schedules = [Schedule.fromJson(data) for data in schJsons['scheduleList']]
        except Exception as e:
            PQLOG.critical(str(e))
        PQLOG.debug("Obtained Schedules from app sync: \n"+json.dumps(self.mainProgram.schedules,default=Schedule.toJson,indent=4))
        self.mainProgram.threadUtil.releaseLock("ScheduleLock")


        #overwrite all schedules
        self.mainProgram.updateScheduleFile()
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        response_message = b"POST request received successfully!"
        self.wfile.write(response_message)

    def startQuest(self, questJson):
        global PQLOG
        self.mainProgram.threadUtil.acquireLock("QuestLock")
        self.mainProgram.activeQuests.append(Quest.fromJson(json.loads(questJson)))
        self.mainProgram.updateActiveQuestsFile()
        self.mainProgram.threadUtil.releaseLock("QuestLock")

    def addKey(self, reward):
        key = reward

        PQLOG.info("Received Key Redemption Request. Attempting to redeem...")
        self.mainProgram.redeemKey(key)

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

    def __init__(self):
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

    def connectToPrivateNetwork(self):
        global PQLOG
        self.attemptingNetworkConnection = True
        
        network_SSID = "WillPhone"
        network_Password = "poopoo1!"
        
        self.connectedToNetwork = WifiUtils.connect_to_wifi(network_SSID,network_Password)

        self.attemptingNetworkConnection = False

    def pollConnection(self):
        global PQLOG
        while(True):
            try:
                wifi = subprocess.check_output(['netsh', 'WLAN', 'show', 'interfaces'], creationflags=subprocess.CREATE_NO_WINDOW)
            except Exception as e:
                self.connectedToNetwork = False
                PQLOG.critical("Failed to scan networks: "+str(e))
                time.sleep(5)
                continue
            data = wifi.decode('utf-8')
            if "WillPhone" in data:
                self.connectedToNetwork = True
            else:
                try:
                    self.PQ_Server.shutdown()
                except Exception as e:
                    pass #likely no server to shut down
                self.connectedToNetwork= False
            time.sleep(5)

    def hostServer(self):
        global PQLOG
        while(True):
            if self.connectedToNetwork:
                try:
                    self.PQ_Server = PQHTTPServer(('172.20.10.5', 1617), PQRequestHandler, self)
                    self.PQ_Server.serve_forever()
                except Exception as e:
                    PQLOG.critical("Failed to continue hosting server, trying again in 5 seconds..."+str(e))
                    time.sleep(5)
            #should only NOT be connected if there is no need or want to be.
            #quest is active -> connectToPrivateNetwork() gets called until connected = true
            #user wants to synchronise schedules -> manual connection -> this else: code checks if its connnected -> connected = true (if it is)
            else:
                time.sleep(3)

    def run(self):
        global PQLOG

        #safety ping to notify starter program that it has started
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(b"alive", ("127.0.0.1", 1617))
        sock.close()

        self.pingCounter = 0
        try:

            #---Create a deadmans switch that shuts down computer if either this program or the switch program is closed
            if not DEBUGMODE:
                PQLOG.info("Activating two-way deadmans switch")
                self.deadmansThread = self.deadmansSwitch.createTwoWaySwitchV2("PasswordQuest.py",SHUTDOWNDELAY)
                self.deadmansThread.start()

            PQLOG.info("loading schedules")
            self.schedules = self.loadSchedules(SCHFLDIR)

            PQLOG.info("Loading active quests")
            self.activeQuests = self.loadQuests(QSTFLDIR)

            PQLOG.info("creating server thread")
            serverThread = threading.Thread(target=self.hostServer)
            serverThread.start()

            PQLOG.info("creating phone connection poller")
            connectionThread = threading.Thread(target=self.pollConnection)
            connectionThread.start()

            PQLOG.info("Init finished... Unlocking and starting now")
            ComputerControl.unblockInput()
            
            self.controlLoop()

        except Exception as e:
            PQLOG.critical("Main loop escaped!")
            self.computerLocked = False #for GUI's status checking
            #external program stops sending/receiving || this means the thread in this program will timeout and shut down pc
        # deadmansSwitch.stopSwitch()
            self.deadmansSwitch.stopAllSwitches()
            PQLOG.critical(f"{e}")
            ComputerControl.unblockInput()

    def checkForQKey(self, quest: Quest) -> str:
        global PQLOG
        foundKey = None
        #try ending active scheduled quest, no need to check if no schedule end keys have been received
        if len(self.receivedKeys) > 0:
            #if active, may be pending on key to end
            questEndKey = quest.questUUID
            for key in self.receivedKeys:
                if questEndKey in key:
                    foundKey = key
        return foundKey
 
    def controlLoop(self):
        global PQLOG

        while(True):
            questsInProgress = False

            #check if key received to end progress of quest

            self.threadUtil.acquireLock("QuestLock")
            
            for quest in self.activeQuests:
                if datetime.now() > quest.expiryDate:
                    quest.isActive = False
                
                if not questsInProgress and quest.isActive:
                    questsInProgress = True

            #remove now-inactive quests
            delCount = 0
            for i in range(len(self.activeQuests)):
                if not self.activeQuests[i - delCount].isActive:
                    self.activeQuests.remove(self.activeQuests[i - delCount])
                    delCount+=1
            if delCount > 0:
                self.updateActiveQuestsFile()
            self.threadUtil.releaseLock("QuestLock")

            self.threadUtil.acquireLock("ScheduleLock")
            for schedule in self.schedules:

                #if scheduled quest inactive, see if it needs to start
                if schedule.isActive:
                    quest = schedule.tryStarting()

                    if quest != None: #if quest was started
                        PQLOG.info("Started quest: "+schedule.scheduleName+" -> "+quest.name)
                        questsInProgress = True
                    
                        self.updateScheduleFile() #update schedule in file as active/with new start time

                        #FIX: this bit should be saved as its own method (since its called in PQRequestHandler.startQuest too)
                        self.threadUtil.acquireLock("QuestLock")
                        self.activeQuests.append(quest)
                        self.threadUtil.releaseLock("QuestLock")
                        self.updateActiveQuestsFile()
            self.threadUtil.releaseLock("ScheduleLock")

            #all keys have been checked and used, so clear them
            #TODO: remove all uses of receivedKeys

            #check computer lock status
            if (questsInProgress or self.syncLock):
                if not self.connectedToNetwork and not self.attemptingNetworkConnection:
                    #connecting to the network will make the hostServer thread start attempting to host the server
                    threading.Thread(target=self.connectToPrivateNetwork).start()
                if not DEBUGMODE:{ComputerControl.blockInput()}
                self.computerLocked = True
            else:
                ComputerControl.unblockInput()
                self.computerLocked = False
            time.sleep(0.1)
    def oldRedeemKey(self, key: str, quest: Quest):
        try:
            data = json.loads(key)
            keyType = data['type']
            acqDate = utils.dateFromJson(data['obtainmentDate'])
            match keyType:
                case 'Complete':
                    #ensure key is not from the future (i.e. cheated with time settings) ##more conditions tbd
                    if acqDate > datetime.now(): 
                        return
                    else:
                        quest.isActive = False
                case 'Failed':
                    pass
                case 'Nullify':
                    # include condition here to check quest wasnt altered to evade lockout
                    #   i.e. if acqDate is during scheduled period then it was possibly deleted to deactivate quest 
                    #       - in this case, continue lockdown for X duration to discourage cheating.
                    quest.expiryDate = datetime.now() + timedelta(minutes=30) 
        except Exception as e:
            PQLOG.critical(str(e))
            quest.isActive = False
        return quest.isActive
    
    def redeemKey(self, key: str):
        self.threadUtil.acquireLock("QuestLock")
        self.threadUtil.acquireLock("ScheduleLock")
        try:
            data = json.loads(key)

            acqDate = utils.dateFromJson(data['obtainmentDate'])
            if acqDate > datetime.now(): 
                return

            scheduler = data['scheduler']
            questUUID = data['questUUID']
            quest = None
            schedule = None

            
            for aq in self.activeQuests:
                if aq.questUUID == questUUID and ( scheduler=="0" or aq.scheduler == scheduler ):
                    quest = aq
                    break
            if quest != None:
                keyType = data['type']
                match keyType:
                    case 'Complete':
                        quest.isActive = False
                        #and repeat, to complete all other instances of this quest (i.e. redeeming yesterday's incomplete quest)
                        #self.redeemKey(key) # currently not good to do due to improper scheduled quest instance handling
                    case 'Cancelled':
                        #if acqDate < quest.startDate #startDate not stored currently
                        quest.isActive = False
                    case 'Failed':
                        #well, at least you tried. expiry soon.
                        quest.expiryDate = datetime.now() + timedelta(minutes=30)
                    case 'Nullify': #not used, replaced with edited/deleted which are not handled
                        # include condition here to check quest wasnt altered to evade lockout
                        #   i.e. if acqDate is during scheduled period then it was possibly deleted to deactivate quest 
                        #       - in this case, continue lockdown for X duration to discourage cheating.
                        quest.expiryDate = datetime.now() + timedelta(minutes=30) 
                    case _: #default / unrecognised key type
                        quest.expiryDate = datetime.now() + timedelta(minutes=30) 
            

            else:
                for sch in self.schedules:
                    if sch.scheduleUUID == scheduler:
                        schedule = sch
                        break
            
            #if completed quest for schedule but schedule not started, autocomplete next scheduled quest instance.
            if schedule != None:
                schedule.updateStartTime()
                self.updateScheduleFile()
            else:
                if not quest.isActive:
                    self.activeQuests.remove(quest)
                self.updateActiveQuestsFile()
        


        except Exception as e:
            PQLOG.critical(str(e))
        self.threadUtil.releaseLock("QuestLock")
        self.threadUtil.releaseLock("ScheduleLock")


    def updateScheduleFile(self):
        PQLOG.info("Saving schedules to file")
        self.threadUtil.acquireLock("FileLock")
        schFile = open(SCHFLDIR, "w")
        schFile.write(json.dumps({'scheduleList':self.schedules},default=Schedule.toJson,indent=4))
        schFile.close()
        self.threadUtil.releaseLock("FileLock")

    def updateActiveQuestsFile(self):
        PQLOG.info("Saving quests to file")
        self.threadUtil.acquireLock("FileLock")
        writtenQuests = open(QSTFLDIR, "w")
        writtenQuests.write(json.dumps({'questList':self.activeQuests},default=Quest.toJson,indent=4))
        writtenQuests.close()
        self.threadUtil.releaseLock("FileLock")  
   
    def loadSchedules(self, schDir):
        PQLOG.info("Loading schedules from file")
        schList: list[Schedule] = []
        self.threadUtil.acquireLock("FileLock")
        try:
            schFile = open(schDir,"r")
            content = schFile.read()
            schFile.close()
            PQLOG.debug("RAW FILE DATA:\n" + repr(content))
            
            schList = [Schedule.fromJson(sch) for sch in json.loads(content)['scheduleList']]
            PQLOG.debug("Loaded:\n"+json.dumps(schList,default=Schedule.toJson,indent=4))
        except KeyError:
            PQLOG.warning("No attribute 'scheduleList' found in schedules.txt. Maybe no schedules to load?")   
        except FileNotFoundError:
            self.threadUtil.releaseLock("FileLock")
            PQLOG.warning(f"Schedule file not found ({SCHFLDIR})")
        except Exception as e:
            PQLOG.critical(str(e))

        self.threadUtil.releaseLock("FileLock")
        return schList   
    def loadQuests(self, qstDir):
        PQLOG.info("Loading quests from file")
        qstList: list[Quest] = []
        self.threadUtil.acquireLock("FileLock")
        try:
            #--- LOAD FROM FILE
            qstFile = open(qstDir,"r")
            content = qstFile.read()
            qstFile.close()
            PQLOG.debug("RAW FILE DATA:\n" + repr(content))

            #--- SAVE TO MEMORY
            qstList = [Quest.fromJson(quest) for quest in json.loads(content)['questList']]
            PQLOG.debug("Loaded:\n"+str(qstList))
            
        except KeyError:
            PQLOG.warning("No attribute 'questList' found in activequests.txt. Maybe no quests to load?")
        except FileNotFoundError:
            self.threadUtil.releaseLock("FileLock")
            PQLOG.warning(f"Quest file not found ({QSTFLDIR})")
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