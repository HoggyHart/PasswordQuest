import logging
import datetime

def set_debug_logger(name):
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(module)s - %(message)s"
    )

    fileHandler = logging.FileHandler("C:/Users/willi/Desktop/code/PasswordQuest/PQPC/logs/"+datetime.datetime.now().__str__().split(':')[0].replace(' ','_')+".log")
    fileHandler.setFormatter(formatter)

    #printHandler = logging.StreamHandler()

    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    handlers = logger.handlers
    for handler in handlers:
        logger.removeHandler(handler)
        
    logger.addHandler(fileHandler)
   #logger.addHandler(printHandler)
    return logger

def printAndLog(logger, msg):
    print(msg)
    logger.debug(msg)