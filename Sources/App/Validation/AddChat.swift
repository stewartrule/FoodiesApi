import Fluent
import Vapor

struct AddChat: Content, Validatable {
    var orderID: UUID
    var message: String

    static func validations(_ validations: inout Validations) {
        validations.add("orderID", as: UUID.self, required: true)
        validations.add(
            "message",
            as: String.self,
            is: .count(1...512),
            required: true
        )
    }
}
