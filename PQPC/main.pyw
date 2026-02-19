import subprocess
import sys
if __name__ == "__main__":
    try:
        subprocess.Popen(
            ["C:/Python314/python.exe", "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/PQPC/iOS_PQPrototypeWaiter.py"],
            creationflags=( subprocess.CREATE_NEW_CONSOLE)
                )
        print('created')
        input()
    except Exception as e:
        print(e)
        input()
        