import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    private weak var viewController: MovieQuizViewController?
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var currentQuestionIndex: Int = 0
    private let questionsAmount: Int = 10
    private var correctAnswers = 0
    private let statisticService: StatisticService = StatisticServiceImplementation()
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        
        self.viewController?.showLoadingIndicator()
        
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.hideLoadingIndicator()
            self?.viewController?.hideImageFrame()
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    func didFailToReceiveNextQuestion(with error: Error) {
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError { [weak self] in
            guard let self = self else { return }
            
            self.viewController?.showLoadingIndicator()
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    func didLoadDataFromServer() {
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError { [weak self] in
            guard let self = self else { return }
            
            self.viewController?.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
    }
    
    // MARK: - Private functions
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        
        viewController?.showLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func noButtonClicked() {
        didAnswer(false)
    }
    
    func yesButtonClicked() {
        didAnswer(true)
    }
    
    private func didAnswer(_ givenAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let isCorrect = (givenAnswer == currentQuestion.correctAnswer)
        if isCorrect {
            correctAnswers += 1
        }
        
        viewController?.showAnswerResult(isCorrect: isCorrect)
    }
    
    func showNextQuestionOrResults() {
        if isLastQuestion() {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            
            let message = """
            Ваш результат: \(correctAnswers)/\(questionsAmount)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
            """
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                message: message,
                buttonText: "Сыграть еще раз")
            viewController?.show(quiz: viewModel)
            viewController?.hideImageFrame()
        } else {
            switchToNextQuestion()
            viewController?.showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
}
