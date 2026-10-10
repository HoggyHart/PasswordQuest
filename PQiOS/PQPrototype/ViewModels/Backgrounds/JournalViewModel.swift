//
//  JournalViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 21/09/2026.
//

import Foundation
import SwiftUI

extension Font {
    
    static let journalBody = Font.custom("Bradley Hand", fixedSize: 20)
    static let journalSubheading = Font.custom("Bradley Hand", size: 25)
    static let journalTitle = Font.custom("Bradley Hand", size: 30)
}

class JournalViewModel: ObservableObject{
    @Published var page = 1
    @Published var pageSide: CGFloat = -1
    init(page: Int = 1, pageSide: CGFloat = -1, lineHeight: CGFloat = 30) {
        self.page = page
        self.pageSide = pageSide
    }
}
