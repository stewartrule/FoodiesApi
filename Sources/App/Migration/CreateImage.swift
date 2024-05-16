import Fluent

struct CreateImage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Image.schema).id()
            .field("name", .string, .required)
            .field("src", .string, .required)
            .field("h", .int16, .required)
            .field("s", .int16, .required)
            .field("b", .int16, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Image.schema).delete()
    }
}
