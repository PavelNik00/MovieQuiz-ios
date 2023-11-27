//
//  ArrayTests.swift
//  MovieQuizTests
//
//  Created by Pavel Nikipelov on 24.11.2023.
//

import Foundation

import XCTest
@testable import MovieQuiz

class ArrayTests: XCTestCase {
    func testGetValueInRage() throws {
        // given
        let array = [1, 1, 2, 3, 5]
        // when
        let value = array[safe: 2]
        //then
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 2)
    }
    
    func testGetValueOutOfRange() throws{
        // given
        let array = [1, 1, 2, 3, 5]
        // when
        let value = array[safe: 3]
        //then
        XCTAssertNotNil(value)
    }
}
