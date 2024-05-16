import Fluent

struct CreateAddress: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Address.schema).id()
            .field("street", .string, .required)
            .field("postal_code_suffix", .string, .required)
            .field("house_number", .int16, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field(
                "postal_area_id",
                .uuid,
                .required,
                .references(PostalArea.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Address.schema).delete()
    }
}
