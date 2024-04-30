import Fluent

struct CreateChat: AsyncMigration {
    func prepare(on database: Database) async throws {
        let sender = try await database.enum("sender").case("customer")
            .case("courier").create()

        try await database.schema(Chat.schema).id()
            .field("created_at", .datetime)
            .field("seen_at", .datetime)
            .field("message", .string, .required)
            .field(
                "order_id",
                .uuid,
                .required,
                .references(Order.schema, "id")
            )
            .field(
                "customer_id",
                .uuid,
                .required,
                .references(Customer.schema, "id")
            )
            .field("courier_id", .uuid, .references(Courier.schema, "id"))
            .field("sender", sender, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Chat.schema).delete()
    }
}
