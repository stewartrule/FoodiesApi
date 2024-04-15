import Vapor

struct ReviewContent: Content {
    let isAnonymous: Bool
    let review: String
    let rating: Double
    let customer: CustomerContent

    static func from(review: BusinessReview) -> Self {
        return ReviewContent(
            isAnonymous: review.isAnonymous,
            review: review.review,
            rating: review.rating,
            customer: CustomerContent.from(customer: review.customer)
        )
    }
}
