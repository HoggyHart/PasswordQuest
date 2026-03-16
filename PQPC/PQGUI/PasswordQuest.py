import tkinter as tk
import sys
sys.path.insert(1, 'C:\\Users\\willi\\Desktop\\code\\PasswordQuest\\PQPC')
import iOS_PQPrototypeWaiter
import threading
import time

class PQWindow(tk.Tk):

    def __init__(self):
        super().__init__()
        self.title("PasswordQuest")
        self.geometry("190x2560")

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
        self.loadSchedulesFrame()

        #Footer
        self.footerFrame = tk.Frame(self.coreFrame)
        self.footerFrame.grid(row=2, sticky = 'NSEW')
        self.loadFooterContent()


    def loadHeaderContent(self):
        #title
        label = tk.Label(self.headerFrame, text="PasswordQuest", font=('Consolas',18))
        label.grid(row=0, column=0, sticky='N')
        
        #status
        self.statusLabel = tk.Label(self.headerFrame, text="Locked (SyncLock)",  font=('Consolas',14), fg="red")
        self.statusLabel.grid(row=1,column=0, sticky='N')
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
        for child in self.bodyFrame.winfo_children():
            child.destroy()

        #test label
        self.scheduleOutput = tk.Label(self.bodyFrame, text="OUTPUT",anchor='n')
        self.scheduleOutput.grid()

    
    def loadQuests(self):
        for child in self.bodyFrame.winfo_children():
            child.destroy()
        text = tk.Label(self.bodyFrame, text="QUESTSS!!!")
        text.grid()

    def loadFooterContent(self):
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
        
        for sch in iOS_PQPrototypeWaiter.schedules:
            newOutput += sch.scheduleName+"\n"
            if sch.questInProgress:
                newOutput += "--->In Progress<---\n"
            elif sch.isActive:
                newOutput += "Starts at "+sch.startTime.__str__()+"\n"
            else:
                newOutput += "Not Active\n"
            newOutput += "\n"

        self.scheduleOutput.config(text=newOutput)

        if not iOS_PQPrototypeWaiter.syncLock:
            if iOS_PQPrototypeWaiter.computerLocked:
                self.statusLabel.config(text="Locked",fg="red")
            else:
                self.statusLabel.config(text="Unlocked", fg="green")
        
    def startAndOutputConsole(self):
        self.mainProcessingThread = threading.Thread(target = iOS_PQPrototypeWaiter.newMain)
        self.mainProcessingThread.start()

        self.outputThread = threading.Thread(target = self.outputLoop)
        self.outputThread.start()

root = PQWindow()
root.initLayout()
root.startAndOutputConsole()
root.mainloop()