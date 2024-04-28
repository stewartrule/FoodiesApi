import Vapor

struct ReviewContent: Content {
    let id: UUID
    let createdAt: Date
    let isAnonymous: Bool
    let businessId: UUID
    let review: String
    let rating: Double
    let customer: CustomerContent

    static func from(review: BusinessReview) throws -> Self {
        return ReviewContent(
            id: try review.requireID(),
            createdAt: review.createdAt ?? Date(),
            isAnonymous: review.isAnonymous,
            businessId: review.$business.id,
            review: review.review,
            rating: review.rating,
            customer: CustomerContent.from(customer: review.customer)
        )
    }
}
