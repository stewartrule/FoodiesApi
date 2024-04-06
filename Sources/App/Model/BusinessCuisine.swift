import Fluent
import Vapor

final class BusinessCuisine: Model, Content {
    static let schema = "business_cuisine"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "business_id")
    var business: Business

    @Parent(key: "cuisine_id")
    var cuisine: Cuisine

    init() {}

    init(
        id: UUID? = nil,
        businessID: Business.IDValue,
        cuisineID: Cuisine.IDValue
    ) {
        self.id = id
        self.$business.id = businessID
        self.$cuisine.id = cuisineID
    }
}
