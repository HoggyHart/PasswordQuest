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
}
