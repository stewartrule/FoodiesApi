import Fluent
import Vapor

final class ProductOrder: Model, Content {
    static let schema = "product_order"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "quantity")
    var quantity: Int

    @Field(key: "price")
    var price: Int

    @Parent(key: "product_id")
    var product: Product

    @Parent(key: "order_id")
    var order: Order

    init() {}

    init(
        id: UUID? = nil,
        quantity: Int,
        price: Int,
        productID: Product.IDValue,
        orderID: Order.IDValue
    ) {
        self.id = id
        self.quantity = quantity
        self.price = price
        self.$product.id = productID
        self.$order.id = orderID
    }
}
