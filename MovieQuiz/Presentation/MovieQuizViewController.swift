import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    
    private var currentQuestion: QuizQuestion?
    
    private let statisticService: StatisticService = StatisticServiceImplementation()
    private let presenter = MovieQuizPresenter()
    
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.viewController = self
        
        let questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        self.questionFactory = questionFactory
        
        showLoadingIndicator()
        questionFactory.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingIndicator()
            self?.show(quiz: viewModel)
            self?.imageView.layer.borderWidth = 0
        }
    }
    
    func didFailToReceiveNextQuestion(with error: Error) {
        hideLoadingIndicator()
        showNetworkError { [weak self] in
            guard let self = self else { return }
            
            self.showLoadingIndicator()
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    func didLoadDataFromServer() {
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        hideLoadingIndicator()
        showNetworkError { [weak self] in
            guard let self = self else { return }
            
            self.showLoadingIndicator()
            self.questionFactory?.loadData()
        }
    }
    
    // MARK: - Actions
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    
    // MARK: - Private functions
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            
            let message = """
            Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
            """
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                message: message,
                buttonText: "Сыграть еще раз")
            show(quiz: viewModel)
            
            imageView.layer.borderWidth = 0
        } else {
            presenter.switchToNextQuestion()
            showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        noButton.isEnabled = false
        yesButton.isEnabled = false
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        noButton.isEnabled = true
        yesButton.isEnabled = true
    }
    
    private func showNetworkError(completion: @escaping () -> Void) {
        let alertModel = AlertModel(title: "Что-то пошло не так(",
                                    message: "Невозможно загрузить данные",
                                    buttonText: "Попробовать еще раз",
                                    accessibilityIdentifier: "Network Error",
                                    completion: completion)
        AlertPresenter(controller: self).showAlert(model: alertModel)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        counterLabel.text = step.questionNumber
        imageView.image = step.image
        textLabel.text = step.question
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let completion = { [weak self] in
            guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            self.showLoadingIndicator()
            self.questionFactory?.requestNextQuestion()
        }
        let alertModel = AlertModel(title: result.title,
                                    message: result.message,
                                    buttonText: result.buttonText,
                                    accessibilityIdentifier: "Game Results",
                                    completion: completion)
        AlertPresenter(controller: self).showAlert(model: alertModel)
    }
}
