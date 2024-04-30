import Fluent

struct CreateCustomer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Customer.schema).id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("email", .string, .required)
            .field("telephone", .string, .required)
            .field("image_id", .uuid, .references(Image.schema, "id"))
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Customer.schema).delete()
    }
}
