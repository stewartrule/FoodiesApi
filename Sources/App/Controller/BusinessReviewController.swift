import Fluent
import Vapor

struct BusinessReviewController: RouteCollection {
    struct Filter: Content, Validatable {
        var businessId: UUID

        static func validations(_ validations: inout Validations) {
            validations.add("businessId", as: UUID.self, required: true)
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(BusinessReview.schema))
        group.get(use: index)
    }

    struct PublicCustomer: Content {
        let firstName: String
        let lastName: String
    }

    struct PublicReview: Content {
        let isAnonymous: Bool
        let review: String
        let rating: Double
        let customer: PublicCustomer
    }

    func index(req: Request) async throws -> Page<PublicReview> {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let businessId = filter.businessId
        let paginator = try await BusinessReview.query(on: req.db)
            .filter(\.$business.$id == businessId)
            .with(\.$customer)
            .sort(\.$createdAt)
            .paginate(for: req)

        return paginator.map { review in
            PublicReview(
                isAnonymous: review.isAnonymous,
                review: review.review,
                rating: review.rating,
                customer: PublicCustomer(
                    firstName: review.customer.firstName,
                    lastName: review.customer.lastName
                )
            )
        }
    }
}
