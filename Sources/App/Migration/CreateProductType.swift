import Fluent

struct CreateProductType: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ProductType.schema).id()
            .field("name", .string, .required)
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(ProductType.schema).delete()
    }
}
