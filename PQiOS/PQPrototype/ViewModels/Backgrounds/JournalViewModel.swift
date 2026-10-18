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
    var lines: Int
    var lineHeight: CGFloat { get{
        400/CGFloat(lines)
    }}
    
    @Published var page = 1
    @Published var pageSide: CGFloat = -1
    init(page: Int = 1, pageSide: CGFloat = -1, lines: Int = 10) {
        self.page = page
        self.pageSide = pageSide
        self.lines = lines
    }
}
