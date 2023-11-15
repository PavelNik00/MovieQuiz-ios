//
//  BestGame.swift
//  MovieQuiz
//
//  Created by Pavel Nikipelov on 03.11.2023.
//

import Foundation

struct BestGame: Codable {
    let correct: Int
    let total: Int
    let date: Date
}

extension BestGame: Comparable {
   static func < (lhs: BestGame, rhs: BestGame) -> Bool {
       lhs.correct < rhs.correct
   }
}
