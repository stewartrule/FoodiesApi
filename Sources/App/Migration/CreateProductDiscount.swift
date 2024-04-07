import Fluent

struct CreateProductDiscount: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ProductDiscount.schema).id()
            .field(
                "discount_id",
                .uuid,
                .required,
                .references(Discount.schema, "id")
            )
            .field(
                "product_id",
                .uuid,
                .required,
                .references(Product.schema, "id")
            )
            .unique(on: "discount_id", "product_id").create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(ProductDiscount.schema).delete()
    }
}
