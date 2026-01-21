import threading
def acquireLock(lock: threading.Lock, lockName: str):
    print("                     --"+threading.current_thread().name+": WAITING FOR "+lockName)
    lock.acquire_lock()
    print("                     --"+threading.current_thread().name+": ACQUIRED "+lockName)

def releaseLock(lock: threading.Lock, lockName: str):
    try:
        lock.release_lock()
        print("                     --"+threading.current_thread().name+": RELEASED "+lockName)
    except:
        pass