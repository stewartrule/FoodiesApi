import Fluent

struct CreateCustomerToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("customer_tokens")
            .id()
            .field("created_at", .datetime)
            .field("value", .string, .required)
            .field(
                "customer_id",
                .uuid,
                .required,
                .references("customers", "id")
            )
            .unique(on: "value")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("customer_tokens").delete()
    }
}
