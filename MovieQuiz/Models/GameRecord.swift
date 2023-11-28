//
//  BestGame.swift
//  MovieQuiz
//
//  Created by Pavel Nikipelov on 03.11.2023.
//

import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(_ another: GameRecord) -> Bool {
        correct > another.correct
    }
}

//extension BestGame: Comparable {
//   static func < (lhs: BestGame, rhs: BestGame) -> Bool {
//       lhs.correct < rhs.correct
//   }
//}
