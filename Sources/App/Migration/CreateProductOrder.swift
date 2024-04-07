import Fluent

struct CreateProductOrder: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ProductOrder.schema)
            .id()
            .field("quantity", .int, .required)
            .field("price", .int, .required)
            .field(
                "order_id",
                .uuid,
                .required,
                .references(Order.schema, "id")
            )
            .field(
                "product_id",
                .uuid,
                .required,
                .references(Product.schema, "id")
            )
            .unique(on: "order_id", "product_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(ProductOrder.schema)
            .delete()
    }
}
