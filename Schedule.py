from datetime import datetime, timedelta
import json
from jsonUtils import boolFromJson, dateFromSwiftString, dateToSwiftString
class Schedule:
    def __init__(self, jsonSch):
        #decode from json
        data = json.loads(jsonSch)
        #simple bools
        self.isActive = boolFromJson(data['isActive'])
        self.questInProgress = boolFromJson(data['questInProgress'])
        self.scheduleInfo_everyXDays = boolFromJson(data['schedule_everyXDays'])
        
        #simple string
        self.scheduleName = str(data['scheduleName'])
        self.questUUID = str(data['scheduleUUID'])

        #int
        self.scheduleInfo_XDayDelay = int(data['schedule_XDayDelay'])

        #dates (formatted "dd-mm-yyyy hh:mm::ss" )
        self.startTime = dateFromSwiftString(str(data['startTime']))
        self.scheduledStartTime = dateFromSwiftString(str(data['scheduledStartTime']))
        self.scheduledEndTime = dateFromSwiftString(str(data['scheduledEndTime']))
        self.scheduleInfo_lastCompletionTime = dateFromSwiftString(str(data['schedule_lastCompletionTime']))

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

    def saveToFile(self, fileDir):
        global fileLock

        #stored with each schedule json split up by double line breaks
        writtenSchedules = Schedule.readListFromFile(fileDir)
        schFile = open(fileDir, "w")

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
        string += "\"scheduleUUID\" : \""+ self.questUUID.__str__()+"\",\n"
        string += "\"schedule_XDayDelay\" : \""+self.scheduleInfo_XDayDelay.__str__()+"\",\n"
        string += "\"startTime\" : \""+dateToSwiftString(self.startTime)+"\",\n"
        string += "\"scheduledStartTime\" : \""+dateToSwiftString(self.scheduledStartTime)+"\",\n"
        string += "\"scheduledEndTime\" : \""+dateToSwiftString(self.scheduledEndTime)+"\",\n"
        string += "\"schedule_lastCompletionTime\" : \""+dateToSwiftString(self.scheduleInfo_lastCompletionTime)+"\",\n"
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
