import Fluent
import Vapor

// @todo
final class Voucher: Model, Content {
    static let schema = "vouchers"

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "valid_from", on: .none)
    var validFrom: Date?

    @Timestamp(key: "valid_until", on: .none)
    var validUntil: Date?

    @Field(key: "discount_percentage")
    var discountPercentage: Int

    @Field(key: "minimum_order_amount")
    var minimumOrderAmount: Int

    @Parent(key: "business_id")
    var business: Business

    @Parent(key: "customer_id")
    var customer: Customer

    @Timestamp(key: "redeemed_at", on: .none)
    var deliveredAt: Date?

    @OptionalParent(key: "order_id")
    var order: Order?

    init() {}

    init(
        id: UUID? = nil,
        businessID: Business.IDValue,
        customerID: Customer.IDValue,
        validFrom: Date,
        validUntil: Date,
        discountPercentage: Int = 0,
        minimumOrderAmount: Int = 0
    ) {
        self.id = id
        self.$business.id = businessID
        self.$customer.id = customerID
    }
}
