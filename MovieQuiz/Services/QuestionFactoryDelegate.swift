protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didFailToReceiveNextQuestion(with error: Error)
    
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}
