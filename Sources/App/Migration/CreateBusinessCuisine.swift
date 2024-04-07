import Fluent

struct CreateBusinessCuisine: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(BusinessCuisine.schema).id()
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .field(
                "cuisine_id",
                .uuid,
                .required,
                .references(Cuisine.schema, "id")
            )
            .unique(on: "business_id", "cuisine_id").create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(BusinessCuisine.schema).delete()
    }
}
