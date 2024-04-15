import Fluent
import Vapor

extension Request {
    var businessReviewRepository: BusinessReviewRepository { .init(req: self) }
}

struct BusinessReviewRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<BusinessReview> {
        BusinessReview.query(on: req.db)
    }

    func paginateFor(businessID: Business.IDValue) async throws -> Page<
        BusinessReview
    > {
        return try await query().filter(\.$business.$id == businessID)
            .with(\.$customer).sort(\.$createdAt).paginate(for: req)
    }

    func getCountFor(businessID: Business.IDValue) async throws -> Int {
        return try await query().filter(\.$business.$id == businessID).count()
    }

    func getAverageRatingFor(businessID: Business.IDValue) async throws
        -> Double
    {
        return try await query().filter(\.$business.$id == businessID)
            .average(\.$rating) ?? 0
    }

    func getCountFor(business: Business) async throws -> Int {
        return try await getCountFor(businessID: try business.requireID())
    }

    func getAverageRatingFor(business: Business) async throws -> Double {
        return try await getAverageRatingFor(
            businessID: try business.requireID()
        )
    }
}
