import subprocess
import sys
if __name__ == "__main__":
    try:
        subprocess.Popen(
            ["C:/Python314/python.exe", "C:/Users/willi/Desktop/code/PasswordQuest/PQPC/iOS_PQPrototypeWaiter.py"],
            creationflags=( subprocess.CREATE_NEW_CONSOLE)
                )
        #create a mini deadmans switch here that tries to get the signal that the process DID start (i.e. didnt get closed early)
        # and shuts down if it doesnt get it within 10 seconds
        print('created')
        input()
    except Exception as e:
        print(e)
        input()
        