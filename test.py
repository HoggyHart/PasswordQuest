import datetime

logFile = open("C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/logs"+"/"+datetime.datetime.now().__str__().split('.')[0].replace(' ','_').replace(':','-')+".txt","w")
logFile.write("line1")
logFile.write("line2!")
logFile.close()