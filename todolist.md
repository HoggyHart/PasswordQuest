# PQPC
- add logging for error catcher in DeadMansSwitch.py for verification that my error catch has no bearing on proper program function
- add handler for keys received that can read whether a quest was completed on time, and store this persistently to prevent access if the most recent quest was failed
- change so that when schedules start their quest the quest is tracked in activequests.txt instead of the schedule object

# PQiOS
- add double-locking mechanism to schedules so 
- A) quest is locked as soon as schedule starts it
- B) A + schedule cannot be changed
- improve schedule locking mechanism to prevent un-locking/schedule changes when locked
- also fix UI in schedule screen. forgot to 
- add tracking for incomplete quests, where the time tracked toward quest completion can be saved and used up for following instances of that quest to incentivise doing them even if the required amount of time cannot be achieved within the time limit.
- add notifications for when scheduled quests start and quests are complete.
- add punishment for time-watching/dilly dallying. If the phone screen is on, slow the rate of active quest completion
- re-add non-active-quest location tracking i.e. enable location tracking when editing a location task.
