import Fluent
import Vapor

struct BusinessController: RouteCollection {
    let businessIDParam = "businessID"

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Business.schema))
        group.get(use: list)
        group.group("recommendations") { group in
            group.get(use: recommendations)
        }
        group.group(":\(businessIDParam)") { group in
            group.get(use: detail)
            group.get("reviews", use: reviews)
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

        let paginator = try await req.orderReviewRepository.paginate(
            for: businessID
        )

        return try paginator.map { review in
            try ReviewContent.from(review: review)
        }
    }

    func recommendations(req: Request) async throws -> BusinessListingContent {
        try BusinessFilter.validate(query: req)
        let filter = try req.query.decode(BusinessFilter.self)
        let distance = filter.distance ?? 10
        let center = CoordinateContent(
            latitude: filter.latitude,
            longitude: filter.longitude
        )

        let businesses = try await req.businessRepository.list(
            near: center,
            distance: distance
        )

        let items: [BusinessContent] = try await businesses.concurrentMap {
            business in
            let products = try await req.productRepository.getDiscounts(
                businessId: business.requireID()
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
        try BusinessFilter.validate(query: req)
        let filter = try req.query.decode(BusinessFilter.self)
        let distance = filter.distance ?? 10
        let center = CoordinateContent(
            latitude: filter.latitude,
            longitude: filter.longitude
        )

        let businesses = try await req.businessRepository.list(
            near: center,
            distance: distance
        )

        let items = try await businesses.concurrentMap { business in
            try await BusinessContent.from(
                req: req,
                business: business,
                products: []
            )
        }

        return BusinessListingContent(
            center: center,
            businesses: items.sorted { lhs, rhs in lhs.distance < rhs.distance }
        )
    }
}
