import Fluent
import Vapor

final class Product: Model, Content {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Field(key: "price")
    var price: Int

    @Parent(key: "business_id")
    var business: Business

    @Parent(key: "product_type_id")
    var productType: ProductType

    @Siblings(
        through: ProductCombo.self,
        from: \.$parent,
        to: \.$child
    )
    var products: [Product]

    @Siblings(
        through: ProductDiscount.self,
        from: \.$product,
        to: \.$discount
    )
    var discounts: [Discount]

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        description: String,
        price: Int,
        businessID: Business.IDValue,
        productTypeID: ProductType.IDValue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.$business.id = businessID
        self.$productType.id = productTypeID
    }
}
