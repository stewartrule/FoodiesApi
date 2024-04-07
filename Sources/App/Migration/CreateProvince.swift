import Fluent

struct CreateProvince: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Province.schema).id()
            .field("name", .string, .required).create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Province.schema).delete()
    }
}
