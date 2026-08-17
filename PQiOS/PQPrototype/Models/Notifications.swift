//
//  Notifications.swift
//  PQPrototype
//
//  Created by William Hart on 17/08/2026.
//

import Foundation
import UserNotifications

class QuestStartNotification: UNMutableNotificationContent{
    
    init(questName: String, scheduleName: String?){
        super.init()
        self.title = scheduleName ?? "Quest Starting"
        self.body = questName + " is starting!"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
