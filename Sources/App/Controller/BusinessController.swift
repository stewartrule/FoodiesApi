import Fluent
import Vapor

struct BusinessController: RouteCollection {
    let businessIDParam = "businessID"

    struct Filter: Content, Validatable {
        var latitude: Double
        var longitude: Double
        var distance: Int? = 10
        var limit: Int? = 100
        var offset: Int? = 0

        static func validations(_ validations: inout Validations) {
            validations.add("latitude", as: Double.self, required: true)
            validations.add("longitude", as: Double.self, required: true)
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
        group.group("recommendations") { subgroup in
            subgroup.get(use: recommendations)
        }
        group.group(":\(businessIDParam)") { subgroup in
            subgroup.get(use: detail)
            subgroup.get("reviews", use: reviews)
        }
    }

    func detail(req: Request) async throws -> BusinessContent {
        guard
            let businessID = req.parameters.get(businessIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        guard
            let business = try await req.businessRepository.find(
                businessID: businessID
            )
        else { throw Abort(.notFound) }

        return try await BusinessContent.from(
            req: req,
            business: business,
            products: business.products
        )
    }

    func reviews(req: Request) async throws -> Page<ReviewContent> {
        guard
            let businessID = req.parameters.get(businessIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        let paginator = try await req.businessReviewRepository.paginateFor(
            businessID: businessID
        )

        return try paginator.map { review in
            try ReviewContent.from(review: review)
        }
    }

    func recommendations(req: Request) async throws -> BusinessListingContent {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let distance = filter.distance ?? 10
        let center = CoordinateContent(
            latitude: filter.latitude,
            longitude: filter.longitude
        )

        let businesses = try await req.businessRepository.list(
            near: center,
            upto: distance
        )

        let items: [BusinessContent] = try await businesses.concurrentMap {
            business in
            let products = try await req.productRepository.getDiscounts(
                businessId: try business.requireID()
            )
            let content = try await BusinessContent.from(
                req: req,
                business: business,
                products: products
            )
            return content
        }

        return BusinessListingContent(
            center: center,
            businesses: items.sorted { lhs, rhs in lhs.distance < rhs.distance }
        )
    }

    func list(req: Request) async throws -> BusinessListingContent {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let distance = filter.distance ?? 10
        let center = CoordinateContent(
            latitude: filter.latitude,
            longitude: filter.longitude
        )

        let businesses = try await req.businessRepository.list(
            near: center,
            upto: distance
        )

        var items: [BusinessContent] = []
        for business in businesses {
            let content = try await BusinessContent.from(
                req: req,
                business: business,
                products: []
            )

            items.append(content)
        }

        return BusinessListingContent(
            center: center,
            businesses: items.sorted { lhs, rhs in lhs.distance < rhs.distance }
        )
    }
}
