//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Pavel Nikipelov on 02.11.2023.
//

import Foundation
import UIKit

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(_ question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}

protocol QuestionFactory {
    func requestNextQuestion()
    func loadData()
}

final class QuestionFactoryImpl {
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
           self.moviesLoader = moviesLoader
           self.delegate = delegate
       }
    
    private var movies: [MostPopularMovie] = []
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
}

extension QuestionFactoryImpl: QuestionFactory {

    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                print("Failed to load image")
            }
            
            let rating = Float(movie.rating) ?? 0
            let ratingForQuestion: Float = [ rating - 1, rating + 1 ].randomElement() ?? 0.0
            let text = "Рейтинг этого фильма больше чем \(Int(ratingForQuestion))?"
            let correctAnswer = rating > ratingForQuestion
            
            let question = QuizQuestion(imageURL: movie.imageURL,
                                        image: UIImage(data: imageData),
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question)
            }
        }
    }
}
