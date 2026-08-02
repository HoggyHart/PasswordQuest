//
//  TimeInABottle.swift
//  PQPrototype
//
//  Created by William Hart on 18/07/2026.
//

import SwiftUI

struct LockedView<LockView: View, Content: View>: View{
    var unlockCon: (() -> Bool)
    var lockView: LockView?
    var content: Content
    var body: some View{
        ZStack{
            content
                .disabled(!unlockCon())
            if unlockCon() == false{
                if lockView != nil { lockView }
                else {
                    ZStack{
                        Image(systemName: "lock.fill")
                    }
                }
                Rectangle().opacity(0)
            }
        }
    }
}

struct TimeInABottleDisplay: View{
    @State var infoDisplay: Bool = false
    
    @ObservedObject private var tiab: TimeInABottle
    init(_ tiab: TimeInABottle){
        self.tiab = tiab
    }
    var body: some View{
        Button{
            infoDisplay = true
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 999).foregroundColor(.yellow)
                RoundedRectangle(cornerRadius: 999).foregroundColor(.white)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
                HStack{
                    Image(systemName: "hourglass")
                    Text("\(tiab.timeStored)")
                }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 10)).foregroundColor(.black)
            }
            .frame(minWidth: 90, idealWidth: 90, maxWidth: 90, minHeight: 30, idealHeight: 30, maxHeight: 30)
        }
        .sheet(isPresented: $infoDisplay, content: {
            Text("Time is stored when quests are completed.\nIt can be spent to delay, skip, and complete failed quests.")
            TimeInABottleUpgradeView(tiab)
            TimeInABottleShopView(tiab)
        })
    }
}


struct TimeInABottleUpgradeView: View{
    @Environment(\.managedObjectContext) private var context
    
    @State var infoDisplay: Bool = false
    
    @ObservedObject var tiab: TimeInABottle
    
    
    init(_ tiab: TimeInABottle){
        self.tiab = tiab
    }
    
//    struct WeeklyCapacityUpgradeView: View {
//        var title: String
//        var unlockText: String
//        var upgradeText: String
//        var body: some View{
//            HStack{
//                Text("Weekly Limit: \(tiab.weeklyTimeCollected)/\(tiab.weeklySoftCap)")
//                Spacer()
//                LockedView(
//                    unlockCon: {
//                        return tiab.weeklyTimeReset! < Date.now
//                    },
//                    lockView: Text(unlockText), content: Button(){
//                        context.perform {
//                            if tiab.updateStoredTime(amount: -Int(tiab.weeklyTimeLimit)){
//                                tiab.weeklyTimeLimit += Int16(TimeInABottle.weeklyCapIncrease)
//                            }
//                            do{try context.save()}catch{}
//                        }
//                    } label:{
//                        HStack{
//                            Text("Upgrade Cost: \(tiab.weeklyTimeLimit)")
//                            Image(systemName: "hourglass")
//                        }
//                    })
//            }
//        }
//    }
    
    @State var upgradeInfoSheet: Bool = false
    
    var body: some View{
        VStack{
            HStack{
                Text("Weekly Limit: \(tiab.weeklyTally)/\(tiab.weeklyCap)").frame(alignment: .center)
                Spacer()
                LockedView(
                    unlockCon: {
                        return tiab.weeklyUpgradeChallengeDate < Date.now
                    },
                    lockView: Text("\((86400*7 - Int(tiab.weeklyUpgradeChallengeDate.timeIntervalSinceNow)) / 86400)/7"),
                    content:
                        Button(){
                            context.perform {
                                if tiab.updateStoredTime(amount: -tiab.weeklyCap){
                                    tiab.weeklyCap += TimeInABottle.weeklyCapIncrease
                                }
                                do{try context.save()}catch{}
                            }
                        } label:{
                            HStack{
                                Text("Upgrade: \(tiab.weeklyCap) \(Image(systemName: "hourglass"))")
                            }
                        }
                )
                if tiab.weeklyUpgradeChallengeDate > Date.now{
                    Button(){
                        upgradeInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                    }
                }
            }.padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                .frame(height: 50)
        }
        .sheet(isPresented: $upgradeInfoSheet, content: {
            Text("Go 7 days without spending Time In A Bottle to unlock.")
        })
    }
}

struct TimeInABottleShopView: View{
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject var tiab: TimeInABottle
    var adminKeyCost = 100
    init(_ tiab: TimeInABottle){
        self.tiab = tiab
    }
    var body: some View{
        Button(){
            buyAdminKey()
        } label : {
            Text("Buy All-In-One Key x1 (\(adminKeyCost))")
        }
    }
    //TODO: make this price reasonable
    func buyAdminKey(){
        context.perform {
            if tiab.updateStoredTime(amount: -adminKeyCost){
                _ = QuestKey.generateAIOKey(context: context)
            }
            
            do{try context.save()}catch{}
        }
    }
}
