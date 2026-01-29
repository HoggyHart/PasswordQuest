//
//  QuestRewardManagerView.swift
//  PQPrototype
//
//  Created by William Hart on 19/01/2026.
//

import SwiftUI
import CoreData

struct QuestRewardManagerView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \QuestReward.obtainmentDate, ascending: false)],animation: .default)
    private var rewards: FetchedResults<QuestReward>
    
    var body: some View {
        VStack{
            Text("Quest Rewards")
            List{
                ForEach(rewards){ reward in
                    Button(){
                        redeemReward(result: reward)
                    } label: {
                        HStack{
                            Image(systemName: reward.completedOnTime ? "checkmark.circle.fill" : "x.circle.fill")
                                .foregroundColor(reward.completedOnTime ? .green : .red)
                            Text("\(reward.quest!.questName!)(\(reward.obtainmentDate!.formatted(date: .numeric, time: .shortened)))")
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    func redeemReward(result: QuestReward){
        if result.completedOnTime == false{
            deleteRewardNotification(offsets: [rewards.firstIndex(of: result)!])
            return
        }
        if let url = URL(string:"http://172.20.10.5:1617/redeem") {
            var request = URLRequest(url: url)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            let key = result.toJson()
            
            let newData = Data(key.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                print("sent")
                if let error = error {
                    // Handle the error
                    print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    print(response.statusCode)
                    if response.statusCode == 200{
                        deleteRewardNotification(offsets: [rewards.firstIndex(of: result)!])
                    }
                }
            }
            task.resume()
        }
    }
    
    private func deleteRewardNotification(offsets: IndexSet) {
        viewContext.perform {
            withAnimation {
                offsets.map {rewards[$0] }.forEach(viewContext.delete)
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
}

#Preview {
    QuestRewardManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
