import UIKit

final class MovieQuizViewController: UIViewController {
    
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var counterLabel: UILabel!
    
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
//    private var currentQuestionIndex = 0
//    private let questionsCount: Int = 10
    
    private var correctAnswers: Int = 0
    
    private var currentQuestion: QuizQuestion?
    private var questionFactory: QuestionFactory?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticService?
    
    private let presenter = MovieQuizPresenter()
    
    private let alert = UIAlertController(
        title: "Этот раунд окончен!",
        message: "Ваш результат ???",
        preferredStyle: .alert)
    
    // MARK: Lifecycle
     
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        
        questionFactory = QuestionFactoryImpl(moviesLoader: MoviesLoader(), delegate: self)
        alertPresenter = AlertPresenterImpl(viewController: self)
        statisticService = StatisticServiceImpl()
        alert.view.accessibilityIdentifier = "Game results"
        
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - Private functions
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alertPresenter?.show(alertModel: model)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderColor = UIColor.clear.cgColor
        textLabel.text = step.question
        imageView.image = step.image
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
    }
    
    private func showAnswerResult(isCorrect: Bool){
        self.yesButton.isEnabled = false
        self.noButton.isEnabled = false
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            correctAnswers += 1
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResult()
            
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
            self.imageView.layer.borderWidth = 0
        }
    }
    
    private func showNextQuestionOrResult() {
        if presenter.isLastQuestion() {
            showFinalResults()
            
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showFinalResults() {
        statisticService?.store(correct: correctAnswers, total: presenter.questionsCount)
        
        let alertModel = AlertModel(
            title: "Игра окончена!",
            message: makeResultMessage(),
            buttonText: "OK",
            buttonAction: { [weak self] in
                self?.presenter.currentQuestionIndex = 0
                self?.correctAnswers = 0
                self?.questionFactory?.requestNextQuestion()
            })

        alertPresenter?.show(alertModel: alertModel)
        alert.view.accessibilityIdentifier = "Game results"
    }
    
    private func makeResultMessage() -> String {
        
        guard let statisticService = statisticService, let bestGame = statisticService.bestGame else {
            assertionFailure("error message")
            return ""
        }
        
        let accuracy = "\(String(format: "%.2f", statisticService.totalAccuracy))%"
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)/\(presenter.questionsCount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)/\(bestGame.total)" + "(\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(accuracy)"
        
        let resultMessage = [
        currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
                              
        return resultMessage
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        let givenAnswer = true
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion?.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        let givenAnswer = false
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion?.correctAnswer)
    }
}

// MARK: QuestionFactoryDelegate

extension MovieQuizViewController: QuestionFactoryDelegate {
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    
    func didReceiveNextQuestion(_ question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        self.currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
}

