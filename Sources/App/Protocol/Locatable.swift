import Foundation

protocol Locatable {
    var latitude: Double { get }
    var longitude: Double { get }
}

extension Locatable {
    private func deg2rad(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180
    }

    func getDistanceTo(_ locatable: Locatable) -> Double {
        let EARTH_RADIUS_KM: Double = 6371.0

        let dLat = deg2rad(locatable.latitude - latitude)
        let dLon = deg2rad(locatable.longitude - longitude)

        let rLat1 = deg2rad(latitude)
        let rLat2 = deg2rad(locatable.latitude)

        let a =
            sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2)
            * cos(rLat1) * cos(rLat2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return EARTH_RADIUS_KM * c
    }
}
