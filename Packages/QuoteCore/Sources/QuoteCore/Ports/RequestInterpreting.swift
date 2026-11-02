import Foundation

public protocol RequestInterpreting {
    func interpret(text: String, catalog: [Item]) -> [ParsedLine]
}
