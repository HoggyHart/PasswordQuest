import tkinter as tk

class PQWindow(tk.Tk):

    def __init__(self):
        super().__init__()
        self.title("PasswordQuest")
        self.geometry("1000x1000")

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
        self.headerFrame.grid(row=0, column=0, sticky='NSEW')
        self.headerFrame.columnconfigure(0,weight=1)
        self.headerFrame.columnconfigure(1,weight=1)
        self.headerFrame.rowconfigure(0,weight=1)
        self.loadHeaderContent()

        #Main Content
        self.bodyFrame = tk.Frame(self.coreFrame)
        self.bodyFrame.grid(row=1, sticky = 'NSEW')
        self.loadSchedulesFrame()

        #Footer
        self.footerFrame = tk.Frame(self.coreFrame)
        self.footerFrame.grid(row=2, sticky = 'NSEW')
        self.loadFooterContent()


    def loadHeaderContent(self):
        #title
        label = tk.Label(self.headerFrame, text="Hello World!", font=('Consolas',18))
        label.grid(row=0, column=0, sticky='NW')
        
        #buttons
        buttonFrame = tk.Frame(self.headerFrame)
        buttonFrame.columnconfigure(0,weight=1)
        buttonFrame.columnconfigure(1,weight=1)
        buttonFrame.columnconfigure(2,weight=1)
        buttonFrame.rowconfigure(0,weight=1)
        buttonFrame.grid(row=0,column=1, sticky='NSW')
        
        schButton = tk.Button(buttonFrame, text= "Schedules",command=self.loadSchedulesFrame)
        schButton.grid(row=0,column=0)
        qstButton = tk.Button(buttonFrame, text= "Quests", command=self.loadQuests)
        qstButton.grid(row=0,column=1)
        syncButton = tk.Button(buttonFrame, text = "Manual Sync")
        syncButton.grid(row=0, column=3, sticky = 'NSEW')

    def loadSchedulesFrame(self):
        for child in self.bodyFrame.winfo_children():
            child.destroy()
        text = tk.Label(self.bodyFrame, text="owhoasd")
        text.grid()
    
    def loadQuests(self):
        for child in self.bodyFrame.winfo_children():
            child.destroy()
        text = tk.Label(self.bodyFrame, text="QUESTSS!!!")
        text.grid()

    def loadFooterContent(self):
        pass

root = PQWindow()
root.initLayout()
root.mainloop()