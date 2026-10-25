import Foundation

/// Cliente de un presupuesto: todo texto libre.
public struct Client: Equatable, Sendable {
    public var name: String
    public var phone: String
    public var address: String
    public var workAddress: String?

    public init(
        name: String = "",
        phone: String = "",
        address: String = "",
        workAddress: String? = nil
    ) {
        self.name = name
        self.phone = phone
        self.address = address
        self.workAddress = workAddress
    }
}
