from datetime import datetime
def dateFromSwiftString(txt: str):
    try:
        date,time = txt.split(',')
        time = time.split(' ')[1]

        d = date.split('/')[0]
        m = date.split('/')[1]
        y = date.split('/')[2]

        h = time.split(':')[0]
        mi = time.split(':')[1]
        s = time.split(':')[2]

        newDate = datetime(year=int(y),month=int(m),day=int(d),hour=int(h),minute=int(mi),second=int(s))
        
        return newDate
    except:
        return None
def dateToSwiftString(date: datetime):
    try:
        txt = ""
        txt += str(date.day) + "/"
        txt += str(date.month) +"/"
        txt += str(date.year) + ", "
        txt += str(date.hour) + ":"
        txt += str(date.minute) + ":"
        txt += str(date.second)
        return txt
    except:
        return "nil"
def boolFromJson(txt: str):
    if txt == "False":
        return False
    return True