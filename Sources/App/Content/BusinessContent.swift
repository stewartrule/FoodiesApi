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

    static func from(req: Request, business: Business, products: [Product] = [])
        async throws -> Self
    {
        let now = Date()
        let image = business.image
        let isOpen = business.isOpenAt(date: now)
        let reviewCount = try await req.orderReviewRepository.getCount(
            for: business
        )
        let averageRating = try await req.orderReviewRepository
            .getAverageRating(for: business)

        return try .init(
            id: business.requireID(),
            name: business.name,
            deliveryCharge: business.deliveryCharge,
            minimumOrderAmount: business.minimumOrderAmount,
            address: business.address,
            image: ImageContent.from(req: req, image: image),
            businessType: business.businessType,
            cuisines: business.cuisines,
            openingHours: business.$openingHours.value != nil
                ? business.openingHours : [],
            isOpen: isOpen,
            distance: 0,
            reviewCount: reviewCount,
            averageRating: averageRating,
            productTypes: business.productTypes,
            products: products.compactMap({ product in
                try ProductContent.from(req: req, product: product)
            })
        )
    }
}
