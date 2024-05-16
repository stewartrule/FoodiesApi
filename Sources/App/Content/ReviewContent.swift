import Vapor

struct ReviewContent: Content {
    let id: UUID
    let createdAt: Date
    let isAnonymous: Bool
    let businessId: UUID
    let review: String
    let rating: Double
    let customer: CustomerContent

    static func from(review: OrderReview) throws -> Self {
        return try ReviewContent(
            id: review.requireID(),
            createdAt: review.createdAt ?? Date(),
            isAnonymous: review.isAnonymous,
            businessId: review.$business.id,
            review: review.review,
            rating: review.rating,
            customer: review.isAnonymous
                ? CustomerContent(firstName: "", lastName: "")
                : CustomerContent.from(customer: review.customer)
        )
    }
}
