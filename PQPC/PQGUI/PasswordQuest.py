import tkinter as tk
import sys
sys.path.insert(1, 'C:\\Users\\willi\\Desktop\\code\\PasswordQuest\\PQPC')
import iOS_PQPrototypeWaiter
from PQCONSTS import PQLOG
import ComputerControl
import threading
import time
import ThreadUtils    
import requests
from datetime import datetime, timedelta
import logging
class PQWindow(tk.Tk):

    def __init__(self):
        super().__init__()
        self.logger = logging.getLogger('root')
        self.title("PasswordQuest")
        self.geometry("190x2560")
        self.mainProcess = iOS_PQPrototypeWaiter.PasswordQuestServer()
        self.wip = PQWIP()

    def initLayout(self):
        self.children.clear()

        # create layout
        self.coreFrame = tk.Frame(self)
        # row 1: Header
        self.coreFrame.rowconfigure(0,weight=1)
        # row 2: main contents
        self.coreFrame.rowconfigure(1,weight=8)
        # row 3: footer
        self.coreFrame.rowconfigure(2,weight=1)
        #stretch to fit
        self.coreFrame.columnconfigure(0, weight=1)
        self.coreFrame.pack(fill='both')

        #Header
        self.headerFrame = tk.Frame(self.coreFrame)
        self.headerFrame.grid(row=0, column=0, sticky='N')
        self.headerFrame.columnconfigure(0,weight=1)
        self.headerFrame.columnconfigure(1,weight=1)
        self.headerFrame.rowconfigure(0,weight=1)
        self.headerFrame.rowconfigure(1,weight=1)
        self.headerFrame.rowconfigure(2,weight=1)
        self.loadHeaderContent()

        #Main Content
        self.bodyFrame = tk.Frame(self.coreFrame)
        self.bodyFrame.grid(row=1, sticky = 'N')
        self.questFrame = tk.Frame(self.bodyFrame)
        self.questFrame.grid(column=0,row=0,sticky='E')
        self.scheduleFrame = tk.Frame(self.bodyFrame)
        self.scheduleFrame.grid(column=1,row=0,sticky='W')
        self.loadSchedulesFrame()
        self.loadQuests()

        #Footer
        self.footerFrame = tk.Frame(self.coreFrame)
        self.footerFrame.grid(row=2, sticky = 'NSEW')
        self.loadFooterContent()


    def loadHeaderContent(self):
        #title
        label = tk.Label(self.headerFrame, text="PasswordQuest", font=('Consolas',18))
        label.grid(row=0, column=0, sticky='N')
        
        #status
        self.statusFrame = tk.Frame(self.headerFrame)
        self.statusFrame.grid(row=1,column=0,sticky='N')

        self.statusLabel = tk.Label(self.statusFrame, text="Locked (SyncLock)",  font=('Consolas',14), fg="red")
        self.statusLabel.grid(row=0,column=0, sticky='N')

        self.connectionStatusLabel = tk.Label(self.statusFrame, text="Connection Status", font = ('Consolas',14), fg='red')
        self.connectionStatusLabel.grid(row=0,column=1,stick='N')

        self.serverStatusLabel = tk.Label(self.statusFrame, text="Server Status", font = ('Consolas',14), fg='red')
        self.serverStatusLabel.grid(row=0,column=2,stick='N')
        #buttons
        buttonFrame = tk.Frame(self.headerFrame)
        buttonFrame.columnconfigure(0,weight=1)
        buttonFrame.columnconfigure(1,weight=1)
        buttonFrame.columnconfigure(2,weight=1)
        buttonFrame.rowconfigure(0,weight=1)
        buttonFrame.grid(row=2,column=0, sticky='N')
        
        schButton = tk.Button(buttonFrame, text= "Schedules",command=self.loadSchedulesFrame)
        schButton.grid(row=0,column=0)
        qstButton = tk.Button(buttonFrame, text= "Quests", command=self.loadQuests)
        qstButton.grid(row=0,column=1)
        syncButton = tk.Button(buttonFrame, text = "Manual Sync")
        syncButton.grid(row=0, column=3, sticky = 'NSEW')

    def loadSchedulesFrame(self):
        #reset view
        for child in self.scheduleFrame.winfo_children():
            child.destroy()

        #test label
        self.scheduleOutput = tk.Label(self.scheduleFrame, text="OUTPUT",anchor='n')
        self.scheduleOutput.grid()

    
    def loadQuests(self):
        for child in self.questFrame.winfo_children():
            child.destroy()

        self.questOutput = tk.Label(self.questFrame, text="QUESTSS!!!")
        self.questOutput.grid()

    def loadFooterContent(self):
        self.lockoutTimeEntryBox = tk.Spinbox(self.footerFrame)
        self.lockoutTimeEntryBox.grid(row=0, column=0)

        self.lockoutButton = tk.Button(self.footerFrame, text="Lockout", command=self.startLockout)
        self.lockoutButton.grid(row=0, column=1)
        pass

    def outputLoop(self):
        while True:
            try:
                self.updateOutput()
            except Exception as e:
                try:
                    self.scheduleOutput.config(text="ERROR: "+str(e))
                except:
                    pass #scheudleoutput is not on frame currently
            time.sleep(2)

    def updateOutput(self):
        newOutput = ""
        schs = self.mainProcess.schedules.copy()

        #quests
        qsts = self.mainProcess.activeQuests.copy()
        i=1
        for qst in qsts:
            newOutput += str(i)+". "+qst.name+"\n"
            i+=1
        self.questOutput.config(text=newOutput)
        newOutput = ""
        #scheudles
        for sch in schs:
            newOutput += sch.scheduleName+"\n"
            #if sch.questInProgress:
                #newOutput += "--->In Progress<---\n"
            if sch.isActive:
                newOutput += "Starts at "+sch.scheduledStartTime.__str__()+"\n"
            else:
                newOutput += "Not Active\n"
            newOutput += "\n"
        self.scheduleOutput.config(text=newOutput)

        #lock status
        if not self.mainProcess.syncLock:
            if self.mainProcess.computerLocked or self.wip.locked:
                self.statusLabel.config(text="Locked |",fg="red")
            else:
                self.statusLabel.config(text="Unlocked |", fg="green")
        if self.mainProcess.connectedToNetwork:
            self.connectionStatusLabel.config(text=" Connected To Phone ",fg="green")
        elif self.mainProcess.attemptingNetworkConnection:
            self.connectionStatusLabel.config(text=" Attempting Connection To Phone ",fg="orange")
        else:
            self.connectionStatusLabel.config(text=" Not Connected To Phone ",fg="red")

        #server status
        try:
            self.logger.debug("Checking server availability")
            status = requests.get('http://172.20.10.5:1617',timeout=5)
            self.logger.debug("Response: "+str(status))
            if status.status_code == 200:
                self.serverStatusLabel.config(text="| Server Online - Successful Pings: "+str(self.mainProcess.pingCounter),fg="green")
            else:
                self.serverStatusLabel.config(text="| Server Online - BUT: "+str(status.status_code),fg="orange")
        except requests.exceptions.ConnectTimeout:
            self.logger.debug("Error updating server status label: Server could not be reached?")
            self.serverStatusLabel.config(text="| Server Offline",fg="red")
        except requests.exceptions.ConnectionError:
            self.logger.debug("Error updating server status label - ConnectionError (obtained connection but no response given)")
            self.serverStatusLabel.config(text="| Server Availability Unclear",fg="orange")
        except Exception as e:
            self.logger.debug("Error updating server status label: "+str(e.__class__) + "/"+str(e))
            self.serverStatusLabel.config(text=str(e),fg="red")

        



    def startLockout(self):
        try:
            threading.Thread(target=self.wip.timedLockout(float(self.lockoutTimeEntryBox.get()))).start()
            self.lockoutButton.config(text=(datetime.now() + timedelta(seconds=int(self.lockoutTimeEntryBox.get()))).__str__())
        except Exception as e:
            PQLOG.warning(str(e))


        
    def startAndOutputConsole(self):
        self.mainProcessingThread = threading.Thread(target = self.mainProcess.run)
        self.mainProcessingThread.start()
        time.sleep(5)
        self.outputThread = threading.Thread(target = self.outputLoop)
        self.outputThread.start()

class PQWIP:
    def __init__(self):
        self.locked = False
    def timedLockout(self, duration):
        if duration is float:
            ComputerControl.blockInput()
            self.locked=True
            time.sleep(duration)
            ComputerControl.unblockInput() #for smoothness, should send 'unblock' signal to main event queue instead so it doesnt temp release during quest lockdown
            self.locked=False

root = PQWindow()
root.initLayout()
root.startAndOutputConsole()
root.mainloop()