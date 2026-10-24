import logging
import datetime

def set_debug_logger(name, ext=None):
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(module)s - %(message)s"
    )

    uniqueFileName = datetime.datetime.now().__str__().split('.')[0].replace(' ','_').replace(':','-') # formats date from i.e.:
    # 2026-07-03 23:59:16.624981
    # --> 2026-07-03_23:59:16

    fileHandler = logging.FileHandler("C:/Users/willi/Desktop/code/PasswordQuest/PQPC/logs/"+uniqueFileName+".log")
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
