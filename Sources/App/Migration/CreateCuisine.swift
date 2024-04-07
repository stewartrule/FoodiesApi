import Fluent

struct CreateCuisine: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Cuisine.schema).id()
            .field("name", .string, .required).create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Cuisine.schema).delete()
    }
}
