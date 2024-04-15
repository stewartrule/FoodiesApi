import Fluent
import Vapor

struct BusinessController: RouteCollection {
    struct Filter: Content, Validatable {
        var postalCode: Int
        var distance: Int? = 10
        var limit: Int? = 100
        var offset: Int? = 0

        static func validations(_ validations: inout Validations) {
            validations.add(
                "postalCode",
                as: Int.self,
                is: .range(1000...9999),
                required: true
            )
            validations.add(
                "distance",
                as: Int?.self,
                is: .nil || .range(2...20),
                required: false
            )
            validations.add(
                "limit",
                as: Int?.self,
                is: .nil || .range(1...100),
                required: false
            )
            validations.add(
                "offset",
                as: Int?.self,
                is: .nil || .range(1...100),
                required: false
            )
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Business.schema))
        group.get(use: list)
        group.group(":businessID") { subgroup in
            subgroup.get(use: detail)
            subgroup.get("reviews", use: reviews)
        }
    }

    func detail(req: Request) async throws -> BusinessContent {
        guard let businessID = req.parameters.get("businessID", as: UUID.self)
        else { throw Abort(.badRequest) }

        guard
            let business = try await req.businessRepository.find(
                businessID: businessID
            )
        else { throw Abort(.notFound) }

        let now = Date()
        let image = business.image
        let isOpen = business.isOpenAt(date: now)
        let reviewCount = try await req.businessReviewRepository.getCountFor(
            business: business
        )
        let averageRating = try await req.businessReviewRepository
            .getAverageRatingFor(business: business)

        return BusinessContent(
            id: try business.requireID(),
            name: business.name,
            deliveryCharge: business.deliveryCharge,
            minimumOrderAmount: business.minimumOrderAmount,
            address: business.address,
            image: try ImageContent.from(req: req, image: image),
            businessType: business.businessType,
            cuisines: business.cuisines,
            openingHours: business.openingHours,
            isOpen: isOpen,
            distance: 0,
            reviewCount: reviewCount,
            averageRating: averageRating,
            productTypes: business.productTypes,
            products: try business.products.map { product in
                try ProductContent.from(req: req, product: product)
            }
        )
    }

    func reviews(req: Request) async throws -> Page<ReviewContent> {
        guard let businessID = req.parameters.get("businessID", as: UUID.self)
        else { throw Abort(.badRequest) }

        let paginator = try await req.businessReviewRepository.paginateFor(
            businessID: businessID
        )

        return paginator.map { review in ReviewContent.from(review: review) }
    }

    func list(req: Request) async throws -> BusinessListingContent {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let postalCode = filter.postalCode
        let distance = filter.distance ?? 10

        guard
            let postalArea = try await PostalArea.query(on: req.db)
                .filter(\.$postalCode == postalCode).first()
        else { throw Abort(.notFound) }

        let businesses = try await req.businessRepository.list(
            near: postalArea,
            upto: distance
        )

        let now = Date()
        var items: [BusinessContent] = []
        for business in businesses {
            let image = business.image
            let isOpen = business.isOpenAt(date: now)
            let distance = business.address.getDistanceTo(postalArea)
            let reviewCount = try await req.businessReviewRepository
                .getCountFor(business: business)
            let averageRating = try await req.businessReviewRepository
                .getAverageRatingFor(business: business)

            items.append(
                BusinessContent(
                    id: try business.requireID(),
                    name: business.name,
                    deliveryCharge: business.deliveryCharge,
                    minimumOrderAmount: business.minimumOrderAmount,
                    address: business.address,
                    image: try ImageContent.from(req: req, image: image),
                    businessType: business.businessType,
                    cuisines: business.cuisines,
                    openingHours: business.openingHours,
                    isOpen: isOpen,
                    distance: distance,
                    reviewCount: reviewCount,
                    averageRating: averageRating,
                    productTypes: business.productTypes,
                    products: []
                )
            )
        }

        return BusinessListingContent(
            center: .init(
                latitude: postalArea.latitude,
                longitude: postalArea.longitude
            ),
            businesses: items.sorted { lhs, rhs in lhs.distance < rhs.distance }
        )
    }
}
