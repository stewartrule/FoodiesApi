import Fluent

struct CreateProductCombo: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ProductCombo.schema).id()
            .field(
                "parent_id",
                .uuid,
                .required,
                .references(Product.schema, "id")
            )
            .field(
                "child_id",
                .uuid,
                .required,
                .references(Product.schema, "id")
            )
            .unique(on: "parent_id", "child_id").create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(ProductCombo.schema).delete()
    }
}
