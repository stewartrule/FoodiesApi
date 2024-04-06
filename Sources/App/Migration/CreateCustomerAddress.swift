import Fluent

struct CreateCustomerAddress: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(CustomerAddress.schema)
            .id()
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
            .unique(on: "customer_id", "address_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(CustomerAddress.schema).delete()
    }
}
