import Fluent
import Vapor

extension Request {
    var productRepository: ProductRepository { .init(req: self) }
}

struct ProductRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Product> { Product.query(on: req.db) }

    func paginateFor(businessId: Business.IDValue) async throws -> Page<Product>
    {
        return try await query().filter(\.$business.$id == businessId)
            .with(\.$productType).with(\.$discounts)
            .with(\.$products, { products in products.with(\.$productType) })
            .paginate(for: req)
    }
}
