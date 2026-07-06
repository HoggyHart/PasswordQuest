//
//  SLTConfigView.swift
//  PQPrototype
//
//  Created by William Hart on 21/06/2026.
//

import Foundation
import SwiftUI

struct SLTConfigView: View{
    
    @ObservedObject
    var task: SingleLocationTask
    
    init(task: SingleLocationTask) {
        self.task = task
    }
    var body: some View{
        Toggle(task.stayInside ? "Stay inside" : "Stay outside", isOn: $task.stayInside)
    }
    
}
