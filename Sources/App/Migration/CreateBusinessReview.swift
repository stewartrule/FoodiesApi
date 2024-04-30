import Fluent

struct CreateBusinessReview: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(BusinessReview.schema).id()
            .field("created_at", .datetime)
            .field("rating", .double, .required)
            .field("review", .string, .required)
            .field("is_anonymous", .bool, .required)
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .field(
                "customer_id",
                .uuid,
                .required,
                .references(Customer.schema, "id")
            )
            .field(
                "order_id",
                .uuid,
                .required,
                .references(Order.schema, "id")
            )
            .unique(on: "business_id", "customer_id", "order_id").create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(BusinessReview.schema).delete()
    }
}
