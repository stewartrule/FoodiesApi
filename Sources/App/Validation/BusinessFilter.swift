import Fluent
import Vapor

struct BusinessFilter: Content, Validatable {
    var latitude: Double
    var longitude: Double
    var distance: Int? = 10
    var limit: Int? = 100
    var offset: Int? = 0

    static func validations(_ validations: inout Validations) {
        validations.add("latitude", as: Double.self, required: true)
        validations.add("longitude", as: Double.self, required: true)
        validations.add(
            "distance",
            as: Int?.self,
            is: .nil || .range(2...20),
            required: false
        )
        validations.add(
            "limit",
            as: Int?.self,
            is: .nil || .range(1...100),
            required: false
        )
        validations.add(
            "offset",
            as: Int?.self,
            is: .nil || .range(1...100),
            required: false
        )
    }
}
