import Fluent

struct CreateDiscount: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Discount.schema).id()
            .field("name", .string, .required)
            .field("percentage", .int16, .required)
            .field("online_date", .datetime, .required)
            .field("offline_date", .datetime, .required)
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Discount.schema).delete()
    }
}
