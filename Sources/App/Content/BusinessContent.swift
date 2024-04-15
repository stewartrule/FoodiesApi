import Vapor

struct BusinessContent: Content {
    let id: Business.IDValue
    let name: String
    let deliveryCharge: Int
    let minimumOrderAmount: Int
    let address: Address
    let image: ImageContent
    let businessType: BusinessType
    let cuisines: [Cuisine]
    let openingHours: [OpeningHours]
    let isOpen: Bool
    let distance: Double
    let reviewCount: Int
    let averageRating: Double
    let productTypes: [ProductType]
    let products: [ProductContent]
}
