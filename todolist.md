# PQPC
- add logging for error catcher in DeadMansSwitch.py for verification that my error catch has no bearing on proper program function
- add handler for keys received that can read whether a quest was completed on time, and store this persistently to prevent access if the most recent quest was failed
- change so that when schedules start their quest the quest is tracked in activequests.txt instead of the schedule object

# PQiOS
- add a better way to manage Location entities (i.e. enable deleting them, allow editing without having to set it as the location for a task)
    - maybe a big map view where it shows all marked locations at the same time (with the ability to hide them) and you can tap on one to read/update/delete, and a + symbol somewhere to create new ones. Should have a list button to see all locations in a list for easy editing (either a sheet or a new view)
- finish implementing Delay mechanism. manually editing start/end times for schedules is tedious
- add tracking for incomplete quests, where the time tracked toward quest completion can be saved and used up for following instances of that quest to incentivise doing them even if the required amount of time cannot be achieved within the time limit.
- add notifications for when scheduled quests start and quests are complete.
- add punishment for time-watching/dilly dallying. If the phone screen is on, slow the rate of active quest completion
- re-add non-active-quest location tracking i.e. enable location tracking when editing a location task.
- add questlines, so if quest A is scheduled from 9-11am, and quest B is scheduled from 13-15, they can be linked so that if quest B just ends 2 hours after A, so if quest A ends early or gets a delayed end, quest B then starts 2 hours after that new end without having to update both quests to account for the delay.
- add schedule extensions/soft ends+hard ends? so if i schedule a quest from 9-11 and need 1 hour, but only track 45 mins before it ends but DO stay there for the remaining 15 mins it can be tracked and be used to unlock the computer still?
- add 1 time failure preventions: if a quest is failed but i NEED computer access, I can get a 1 time key in exchange for my an upcoming quest doubling in requirement/not unlocking pc or something
