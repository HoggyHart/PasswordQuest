import iOS_PQPrototypeWaiter

me = iOS_PQPrototypeWaiter.PasswordQuestServer()
me.schedules = me.loadSchedules(schDir=iOS_PQPrototypeWaiter.SCHFLDIR)

sch = me.schedules[-1]
print(sch)
sch.updateStartTime()
print(sch)