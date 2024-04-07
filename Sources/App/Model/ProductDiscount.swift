import Fluent
import Vapor

final class ProductDiscount: Model, Content {
    static let schema = "product_discount"

    @ID(key: .id) var id: UUID?

    @Parent(key: "product_id") var product: Product

    @Parent(key: "discount_id") var discount: Discount

    init() {}

    init(
        id: UUID? = nil,
        productID: Product.IDValue,
        discountID: Discount.IDValue
    ) {
        self.id = id
        self.$product.id = productID
        self.$discount.id = discountID
    }
}
