import Fluent

struct CreateBusinessType: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(BusinessType.schema)
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(BusinessType.schema)
            .delete()
    }
}
