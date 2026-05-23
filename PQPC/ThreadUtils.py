import threading
import logging
import logger

class ThreadUtility:

    def __init__(self):
        self.lockList = dict()

    def getLock(self, lockName: str):
        if self.lockList.get(lockName) != None:
            return self.lockList.get(lockName)
        else:
            self.lockList[lockName] = threading.Lock()
            return self.lockList[lockName]

    def acquireLock(self, lockName: str):
        print(logging.getLogger("root").handlers)
        lock = self.getLock(lockName)
        logger = logging.getLogger("root")
        logger.debug("                     --"+threading.current_thread().name+": WAITING FOR "+lockName)
        lock.acquire_lock()
        logger.debug("                     --"+threading.current_thread().name+": ACQUIRED "+lockName)

    def releaseLock(self, lockName: str):
        try:
            lock = self.getLock(lockName)
            lock.release_lock()
            logger = logging.getLogger("root")
            logger.debug("                     --"+threading.current_thread().name+": RELEASED "+lockName)
        except:
            pass #lock already released