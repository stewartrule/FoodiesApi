import Fluent
import Vapor

final class OrderReview: Model, Content {
    static let schema = "order_review"

    @ID(key: .id) var id: UUID?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Field(key: "review") var review: String

    @Field(key: "rating") var rating: Double

    @Field(key: "is_anonymous") var isAnonymous: Bool

    @Parent(key: "business_id") var business: Business

    @Parent(key: "customer_id") var customer: Customer

    @Parent(key: "order_id") var order: Order

    init() {}

    init(
        id: UUID? = nil,
        review: String,
        rating: Double,
        isAnonymous: Bool,
        businessID: Business.IDValue,
        customerID: Customer.IDValue,
        orderID: Order.IDValue
    ) {
        self.id = id
        self.review = review
        self.rating = rating
        self.isAnonymous = isAnonymous
        self.$business.id = businessID
        self.$customer.id = customerID
        self.$order.id = orderID
    }
}
