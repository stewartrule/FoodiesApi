import Fluent
import Vapor

struct BusinessController: RouteCollection {
    struct Filter: Content, Validatable {
        var postalCode: Int
        var distance: Int? = 10
        var limit: Int? = 100
        var offset: Int? = 0

        static func validations(
            _ validations: inout Validations
        ) {
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

    struct BusinessContent: Content {
        let id: Business.IDValue
        let business: Business
        let isOpen: Bool
        let distance: Double
        let reviewCount: Int
        let averageRating: Double
    }

    struct CustomerContent: Content {
        let firstName: String
        let lastName: String

        static func from(customer: Customer) -> Self {
            CustomerContent(
                firstName: customer.firstName,
                lastName: customer.lastName
            )
        }
    }

    struct ReviewContent: Content {
        let isAnonymous: Bool
        let review: String
        let rating: Double
        let customer: CustomerContent

        static func from(review: BusinessReview) -> Self {
            return ReviewContent(
                isAnonymous: review.isAnonymous,
                review: review.review,
                rating: review.rating,
                customer: CustomerContent.from(
                    customer: review.customer
                )
            )
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(
            .constant(Business.schema)
        )
        group.get(use: filter)
        group.group(":businessID") { subgroup in
            subgroup.get(use: detail)
            subgroup.get("reviews", use: reviews)
        }
    }

    func detail(req: Request) async throws
        -> BusinessContent
    {
        guard
            let businessID = req.parameters.get(
                "businessID",
                as: UUID.self
            )
        else {
            throw Abort(.badRequest)
        }

        guard
            let business = try await req.businessRepository
                .find(
                    businessID: businessID
                )
        else {
            throw Abort(.notFound)
        }

        let now = Date()
        let isOpen = business.isOpenAt(date: now)
        let reviewCount =
            try await req.businessReviewRepository
            .getCountFor(business: business)
        let averageRating =
            try await req.businessReviewRepository
            .getAverageRatingFor(business: business)

        return BusinessContent(
            id: try business.requireID(),
            business: business,
            isOpen: isOpen,
            distance: 0,
            reviewCount: reviewCount,
            averageRating: averageRating
        )
    }

    func reviews(req: Request) async throws -> Page<
        ReviewContent
    > {
        guard
            let businessID = req.parameters.get(
                "businessID",
                as: UUID.self
            )
        else {
            throw Abort(.badRequest)
        }

        let paginator =
            try await req.businessReviewRepository
            .paginateFor(businessID: businessID)

        return paginator.map { review in
            ReviewContent.from(review: review)
        }
    }

    func filter(req: Request) async throws
        -> [BusinessContent]
    {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let postalCode = filter.postalCode
        let distance = filter.distance ?? 10

        guard
            let postalArea =
                try await PostalArea
                .query(on: req.db)
                .filter(\.$postalCode == postalCode)
                .first()
        else {
            throw Abort(.notFound)
        }

        let businesses = try await req.businessRepository
            .find(
                near: postalArea,
                upto: distance
            )

        let now = Date()
        var aggregates: [BusinessContent] = []
        for business in businesses {
            let isOpen = business.isOpenAt(date: now)
            let distance = business.address.getDistanceTo(
                postalArea
            )
            let reviewCount =
                try await req.businessReviewRepository
                .getCountFor(business: business)
            let averageRating =
                try await req.businessReviewRepository
                .getAverageRatingFor(business: business)

            aggregates.append(
                BusinessContent(
                    id: try business.requireID(),
                    business: business,
                    isOpen: isOpen,
                    distance: distance,
                    reviewCount: reviewCount,
                    averageRating: averageRating
                )
            )
        }

        return aggregates.sorted { lhs, rhs in
            lhs.distance < rhs.distance
        }
    }
}
