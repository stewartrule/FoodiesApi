import Fluent

struct CreateOpeningHours: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(OpeningHours.schema)
            .id()
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .field("weekday", .int16, .required)
            .field("start_time", .int16, .required)
            .field("end_time", .int16, .required)
            .field("is_closed", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(OpeningHours.schema).delete()
    }
}
