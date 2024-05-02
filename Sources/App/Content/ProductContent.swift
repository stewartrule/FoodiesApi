import Vapor

struct ProductContent: Content {
    let id: Product.IDValue
    let name: String
    let description: String
    let products: [ProductContent]
    let productType: ProductType
    let price: Int
    let discounts: [Discount]
    let image: ImageContent

    static func from(req: Request, product: Product) throws -> Self {
        try .init(
            id: product.requireID(),
            name: product.name,
            description: product.description,
            products: product.products.map { product in
                try ProductContent.from(req: req, product: product)
            },
            productType: product.productType,
            price: product.price,
            discounts: product.discounts,
            image: ImageContent.from(req: req, image: product.image)
        )
    }
}
