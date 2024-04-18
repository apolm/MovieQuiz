import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func showAnswerResult(isCorrect: Bool)
    func hideAnswerResult()
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel, completion: @escaping () -> Void)
    
    func showNetworkError(completion: @escaping () -> Void)
}
