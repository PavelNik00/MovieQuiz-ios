//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Pavel Nikipelov on 27.11.2023.
//

import UIKit

final class MovieQuizPresenter {
    let questionsCount: Int = 10
    var currentQuestionIndex: Int = 0
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsCount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: model.image ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsCount)")
    }
    
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func didReceiveNextQuestion(_ question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        self.currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    var correctAnswers: Int = 0
    var questionFactory: QuestionFactory?
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
//            let text = "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"
//                        
//                        let viewModel = QuizResultsViewModel(
//                            title: "Этот раунд окончен!",
//                            text: text,
//                            buttonText: "Сыграть ещё раз")
//                            viewController?.show(quiz: viewModel)
            showFinalResults()
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    var statisticService: StatisticService?
    var alertPresenter: AlertPresenter?

    func showFinalResults() {
        statisticService?.store(correct: correctAnswers, total: self.questionsCount)
        
        let alertModel = AlertModel(
            title: "Игра окончена!",
            message: makeResultMessage(),
            buttonText: "OK",
            buttonAction: { [weak self] in
                self?.currentQuestionIndex = 0
                self?.correctAnswers = 0
                self?.questionFactory?.requestNextQuestion()
            })

        alertPresenter?.show(alertModel: alertModel)
//        alert.view.accessibilityIdentifier = "Game results"
    }
    
    func makeResultMessage() -> String {
        
        guard let statisticService = statisticService, let bestGame = statisticService.bestGame else {
            assertionFailure("error message")
            return ""
        }
        
        let accuracy = "\(String(format: "%.2f", statisticService.totalAccuracy))%"
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)/\(self.questionsCount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)/\(bestGame.total)" + "(\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(accuracy)"
        
        let resultMessage = [
        currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
                              
        return resultMessage
    }

}
