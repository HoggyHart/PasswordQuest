//
//  JournalViewModel.swift
//  PQPrototype
//
//  Created by William Hart on 21/09/2026.
//

import Foundation

class JournalViewModel: ObservableObject{
    @Published var page = 1
    @Published var pageSide: CGFloat = -1
    let lineHeight: CGFloat
    init(page: Int = 1, pageSide: CGFloat = -1, lineHeight: CGFloat = 30) {
        self.page = page
        self.pageSide = pageSide
        self.lineHeight = lineHeight
    }
}
