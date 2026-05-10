
import SwiftUI

protocol NetworkDelegate: AnyObject {
    func didFinish()
}

class NetworkService {
    // ПОМИЛКА: Делегат без 'weak'
    var delegate: NetworkDelegate?

    // ПОМИЛКА: Хардкод токена
    let apiToken = "ab123-cd456-secret"

    // ПРАВЛЬНО: слабке посилання
    weak var safeDelegate: NetworkDelegate?
}
