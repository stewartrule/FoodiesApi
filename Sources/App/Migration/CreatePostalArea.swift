import Fluent

struct CreatePostalArea: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(PostalArea.schema).id()
            .field("postal_code", .int16, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("city_id", .uuid, .required, .references(City.schema, "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(PostalArea.schema).delete()
    }
}
