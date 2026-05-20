import ThreadUtils
import threading
import time
import logger

logger.set_debug_logger("root")
obj = ThreadUtils.ThreadUtility()

obj.acquireLock("MyLock")
def fun():
    obj.acquireLock("MyLock")
threading.Thread(target=fun).start()
time.sleep(1)
obj.releaseLock("MyLock")