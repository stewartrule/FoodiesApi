import Vapor

struct ProductOrderContent: Content {
    let id: UUID
    let quantity: Int
    let price: Int
    let product: ProductContent

    static func from(req: Request, item: ProductOrder) throws -> Self {
        .init(
            id: try item.requireID(),
            quantity: item.quantity,
            price: item.price,
            product: try ProductContent.from(req: req, product: item.product)
        )
    }
}
