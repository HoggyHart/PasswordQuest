import subprocess
import sys
if __name__ == "__main__":
    try:
        subprocess.Popen(
            ["python3", "C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/iOS_PQPrototypeWaiter.py"],
            creationflags=( subprocess.CREATE_NEW_CONSOLE |
                subprocess.CREATE_NEW_PROCESS_GROUP)
                )
        print('created')
    except Exception as e:
        print(e)
        input()
        