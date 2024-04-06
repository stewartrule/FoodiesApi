import Fluent

struct CreateProduct: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Product.schema)
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("price", .int, .required)
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .field(
                "product_type_id",
                .uuid,
                .required,
                .references(ProductType.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Product.schema).delete()
    }
}
