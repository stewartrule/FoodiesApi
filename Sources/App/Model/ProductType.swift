import Fluent
import Vapor

final class ProductType: Model, Content {
    static let schema = "product_types"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    @Parent(key: "business_id") var business: Business

    init() {}

    init(id: UUID? = nil, name: String, businessID: Business.IDValue) {
        self.id = id
        self.name = name
        self.$business.id = businessID
    }
}
