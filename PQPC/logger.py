import logging
import datetime

def set_custom_logger(name):
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(module)s - %(message)s"
    )

    fileHandler = logging.FileHandler("C:/Users/willi/OneDrive/Desktop/code/PasswordQuest/PQPC/logs/"+datetime.datetime.now().__str__().split('.')[0].replace(' ','_').replace(':','-')+".log")
    fileHandler.setFormatter(formatter)

    printHandler = logging.StreamHandler()

    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    logger.addHandler(fileHandler)
    logger.addHandler(printHandler)
    return logger