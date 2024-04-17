import UIKit

final class MovieQuizViewController: UIViewController {
    private var presenter: MovieQuizPresenter!
    
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
        
        presenter = MovieQuizPresenter(viewController: self)
    }
    
    // MARK: - Actions
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        presenter.yesButtonClicked()
    }
    
    // MARK: - Private functions
    func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.presenter.showNextQuestionOrResults()
        }
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        noButton.isEnabled = false
        yesButton.isEnabled = false
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        noButton.isEnabled = true
        yesButton.isEnabled = true
    }
    
    func hideImageFrame() {
        imageView.layer.borderWidth = 0
    }
    
    func showNetworkError(completion: @escaping () -> Void) {
        let alertModel = AlertModel(title: "Что-то пошло не так(",
                                    message: "Невозможно загрузить данные",
                                    buttonText: "Попробовать еще раз",
                                    accessibilityIdentifier: "Network Error",
                                    completion: completion)
        AlertPresenter(controller: self).showAlert(model: alertModel)
    }
    
    func show(quiz step: QuizStepViewModel) {
        counterLabel.text = step.questionNumber
        imageView.image = step.image
        textLabel.text = step.question
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let completion = { [weak self] in
            guard let self = self else { return }
            self.presenter.restartGame()
        }
        let alertModel = AlertModel(title: result.title,
                                    message: result.message,
                                    buttonText: result.buttonText,
                                    accessibilityIdentifier: "Game Results",
                                    completion: completion)
        AlertPresenter(controller: self).showAlert(model: alertModel)
    }
}
