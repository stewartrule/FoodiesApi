import Fluent

struct CreateCourier: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Courier.schema).id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("telephone", .string, .required)
            .field("image_id", .uuid, .references(Image.schema, "id")).create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Courier.schema).delete()
    }
}
