//
//  ComplexityCalculator.swift
//  Analyzer
//
//  Created by Yaroslav Liashevych on 10.05.2026.
//

import Foundation
import SwiftSyntax

struct ComplexityCalculator {

    /// Розраховує цикломатичну складність.
    /// Визначає кількість лінійно незалежних маршрутів через програмний код.
    static func calculate(for body: CodeBlockSyntax?) -> Int {
        guard let body = body else { return 1 }

        let tokens = body.tokens(viewMode: .all).map { $0.tokenKind }

        let decisionPoints = tokens.filter { kind in
            switch kind {
            // Точки розгалуження, які збільшують складність
            case .keyword(.if),
                 .keyword(.guard),
                 .keyword(.for),
                 .keyword(.while),
                 .keyword(.case),
                 .keyword(.catch):
                return true
            default:
                return false
            }
        }

        // Базова складність будь-якої функції дорівнює 1
        return 1 + decisionPoints.count
    }
}

