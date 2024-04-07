import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Order.schema)
            .id()
            .field("created_at", .datetime)
            .field("prepared_at", .datetime)
            .field("sent_at", .datetime)
            .field("delivered_at", .datetime)
            .field(
                "customer_id",
                .uuid,
                .required,
                .references(Customer.schema, "id")
            )
            .field(
                "address_id",
                .uuid,
                .required,
                .references(Address.schema, "id")
            )
            .field(
                "business_id",
                .uuid,
                .required,
                .references(Business.schema, "id")
            )
            .field(
                "courier_id",
                .uuid,
                .references(Courier.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Order.schema).delete()
    }
}
