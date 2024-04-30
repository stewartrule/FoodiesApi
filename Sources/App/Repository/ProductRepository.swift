import Fluent
import Vapor

extension Request {
    var productRepository: ProductRepository { .init(req: self) }
}

struct ProductRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Product> { Product.query(on: req.db) }

    func getDiscounts(businessId: Business.IDValue, limit: Int = 8) async throws
        -> [Product]
    {
        return try await query().filter(\.$business.$id == businessId)
            .join(Business.self, on: \Product.$business.$id == \Business.$id)
            .join(Discount.self, on: \Discount.$business.$id == \Business.$id)
            .join(
                ProductDiscount.self,
                on: \ProductDiscount.$product.$id == \Product.$id
            )
            .with(\.$productType)
            .with(\.$discounts)
            .with(\.$productType)
            .with(\.$discounts)
            .with(\.$image)
            .with(
                \.$products,
                { products in
                    products
                        .with(\.$productType)
                        .with(\.$products)
                        .with(\.$image)
                        .with(\.$discounts)
                }
            )
            .limit(limit).all()
    }
}
