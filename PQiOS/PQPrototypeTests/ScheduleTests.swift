////
////  ScheduleTests.swift
////  PQPrototypeTests
////
////  Created by William Hart on 24/08/2026.
////
//
import XCTest
import CoreData
@testable import PQPrototype
//
final class ScheduleTests: XCTestCase {
//    
    var context: NSManagedObjectContext!
    var quest: Quest!
    var schedule: Schedule!
//
    func createInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let context = PersistenceController().container.viewContext
        return context
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        context = createInMemoryManagedObjectContext()
        quest = Quest(context: context, name: "TestQuest")
        schedule = Schedule(context: context, quest: quest)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testXDayDelaySchedule() throws {
        for i in 1..<365{
            schedule.xDayDelay = Int32(i)
            
            let dateA = schedule.scheduledStartTime
            schedule.scheduledStartTime = schedule.getNext_XDayDelay_StartTime(fromDate: schedule.scheduledStartTime!)
            XCTAssertEqual(schedule.scheduledStartTime, dateA?.addingTimeInterval(TimeInterval(86400*i)))
        }
    }
    
    func testWeekdaySchedule() throws {
        schedule.everyXDays=false
        schedule.scheduledDays = Week()
        
        XCTAssertNil(schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart))
        
        schedule.isActive = true
        schedule.scheduledDays = Week(arrayLiteral: .monday, .wednesday, .friday, .sunday)
        var sDate = Calendar.current.date(bySetting: .weekday, value: 2, of: Date.now)!
        sDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: sDate)!
        schedule.scheduledStartTime = sDate
        
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*2), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*2), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*2), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*1), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*2), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        
        schedule.scheduledDays = Week(arrayLiteral: .monday)
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*5), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
        schedule.nextScheduledStart = schedule.getNext_ScheduledDays_StartTime(fromDate: schedule.nextScheduledStart)!
        XCTAssertEqual(sDate.addingTimeInterval(86400*7), schedule.scheduledStartTime)
        sDate = schedule.nextScheduledStart
    }
    
    func testUpdateSchedule() {
        let nextDate = schedule.scheduledStartTime?.addingTimeInterval(86400)
        
        schedule.updateSchedule()
        XCTAssertEqual(schedule.scheduledStartTime, schedule.startTime)
        XCTAssertEqual(schedule.scheduledStartTime, nextDate)
        XCTAssertEqual(schedule.scheduledEndTime, schedule.scheduledStartTime?.addingTimeInterval(86400))
    }
    
//
//    func daysOfTheWeekScheduleTest() throws {
//        
//    }
//
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//
}
