import Fluent

struct CreateImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Image.schema).id()
            .field("name", .string, .required)
            .field("original_id", .int, .required)
            .field("h", .int, .required)
            .field("s", .int, .required)
            .field("b", .int, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Image.schema).delete()
    }
}
