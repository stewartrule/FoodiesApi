import Vapor

struct CoordinateContent: Content, Locatable {
    var latitude: Double
    var longitude: Double
}
