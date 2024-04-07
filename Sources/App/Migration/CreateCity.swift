import Fluent

struct CreateCity: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(City.schema).id()
            .field("name", .string, .required)
            .field(
                "province_id",
                .uuid,
                .required,
                .references(Province.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(City.schema).delete()
    }
}
