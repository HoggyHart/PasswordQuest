import threading
import logging
 
def acquireLock(lock: threading.Lock, lockName: str):
    logger = logging.getLogger("root")
    logger.debug("                     --"+threading.current_thread().name+": WAITING FOR "+lockName)
    lock.acquire_lock()
    logger.debug("                     --"+threading.current_thread().name+": ACQUIRED "+lockName)

def releaseLock(lock: threading.Lock, lockName: str):
    try:
        lock.release_lock()
        logger = logging.getLogger("root")
        logger.debug("                     --"+threading.current_thread().name+": RELEASED "+lockName)
    except:
        pass