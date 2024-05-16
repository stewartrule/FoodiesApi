import Fluent
import Vapor

struct UpdateReview: Content, Validatable {
    var reviewID: UUID
    var orderID: UUID
    var isAnonymous: Bool
    var review: String
    var rating: Int

    static func validations(_ validations: inout Validations) {
        validations.add("reviewID", as: UUID.self, required: true)
        validations.add("orderID", as: UUID.self, required: true)
        validations.add("isAnonymous", as: Bool.self, required: true)
        validations.add(
            "review",
            as: String.self,
            is: .count(3...256),
            required: true
        )
        validations.add(
            "rating",
            as: Int.self,
            is: .range(1...5),
            required: true
        )
    }
}
