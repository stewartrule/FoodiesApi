import Fluent
import Vapor

extension Request {
    var orderReviewRepository: OrderReviewRepository { .init(req: self) }
}

struct OrderReviewRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<OrderReview> {
        OrderReview.query(on: req.db)
    }

    func paginate(for businessID: Business.IDValue) async throws -> Page<
        OrderReview
    > {
        return try await query()
            .filter(\.$business.$id == businessID)
            .with(\.$customer)
            .sort(\.$createdAt)
            .paginate(for: req)
    }

    func allBy(order: Order) async throws -> [OrderReview] {
        return try await query()
            .filter(\.$order.$id == order.requireID())
            .with(\.$customer)
            .sort(\.$createdAt)
            .all()
    }

    func firstBy(profileID: Customer.IDValue, reviewID: OrderReview.IDValue)
        async throws -> OrderReview?
    {
        return try await query()
            .filter(\.$id == reviewID)
            .filter(\.$customer.$id == profileID)
            .with(\.$customer)
            .sort(\.$createdAt)
            .first()
    }

    func getCount(for businessID: Business.IDValue) async throws -> Int {
        return try await query().filter(\.$business.$id == businessID).count()
    }

    func getAverageRating(for businessID: Business.IDValue) async throws
        -> Double
    {
        return try await query().filter(\.$business.$id == businessID)
            .average(\.$rating) ?? 0
    }

    func getCount(for business: Business) async throws -> Int {
        return try await getCount(for: try business.requireID())
    }

    func getAverageRating(for business: Business) async throws -> Double {
        return try await getAverageRating(
            for: try business.requireID()
        )
    }
}
