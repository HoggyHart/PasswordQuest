import win32con
import win32api
import ctypes

def blockInput():
    ctypes.windll.user32.BlockInput(True)
    pass

def screenOff():
    ctypes.windll.user32.SendMessageW(65535, 274, 61808, 2)

def unblockInput():
    ctypes.windll.user32.BlockInput(False)
def screenOn():
    ctypes.windll.user32.SendMessageW(65535, 274, 61808, -1)
    move_cursor()
    
def move_cursor():
    x, y = (0,0)
    win32api.mouse_event(win32con.MOUSEEVENTF_MOVE, x, y)