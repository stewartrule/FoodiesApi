import Fakery
import Fluent
import Vapor

struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Seed database with mock data"
    }

    func run(
        using context: CommandContext,
        signature: Signature
    ) async throws {
        let faker = Faker(locale: "nl")
        let app = context.application
        let database = app.db
        let console = context.console

        // Gather input data.
        let jsonResource = JsonResource(
            app: app,
            fileManager: FileManager.default
        )
        var postalCodes = try jsonResource.getPostalCode()
        let restaurants = try jsonResource.getRestaurants()
        let dishes = try jsonResource.getDishes()
        let provincesNames =
            postalCodes
            .map({ $0.province.rawValue })
            .uniqued()
            .map({ $0 })

        // Determine density of the seed.
        let province = console.choose(
            "Province(s)",
            from: ["All"] + provincesNames
        )
        if province == "All" {
            let density = console.choose(
                "Density",
                from: [
                    "Low", "Medium", "High", "Very high",
                ]
            )
            let divisor =
                switch density {
                    case "Low": 22
                    case "Medium": 11
                    case "High": 4
                    case "Very high": 1
                    default: 11
                }
            postalCodes = postalCodes.filter({
                $0.postalCode % divisor == 0
            })
        } else {
            postalCodes = postalCodes.filter({
                $0.province.rawValue == province
            })
        }

        // Create product types
        let productTypes =
            dishes
            .map({ $0.dishtype })
            .uniqued()
            .map({ ProductType(name: $0) })
        try await productTypes.create(on: database)
        console.output("Created productTypes")

        // Create provinces
        let provinces =
            provincesNames
            .map({ Province(name: $0) })
        try await provinces.create(on: database)
        console.output("Created provinces")

        // Create cities
        let cities = try provinces.flatMap { province in
            try postalCodes
                .filter({
                    $0.province.rawValue == province.name
                })
                .map({ $0.city })
                .uniqued()
                .compactMap { cityName in
                    City(
                        name: cityName,
                        provinceID: try province.requireID()
                    )
                }
        }
        try await cities.create(on: database)
        console.output("Created cities")

        // Create postal areas
        let postalAreas = try cities.flatMap { city in
            try postalCodes
                .filter({ $0.city == city.name })
                .compactMap { postalCode in
                    return PostalArea(
                        postalCode: postalCode.postalCode,
                        latitude: postalCode.latitude,
                        longitude: postalCode.longitude,
                        cityID: try city.requireID()
                    )
                }
        }
        try await postalAreas.create(on: database)
        console.output("Created postalAreas")

        // Create addresses
        var addresses: [Address] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for postalArea in postalAreas {
            let latitude = postalArea.latitude
            let longitude = postalArea.longitude
            let address = Address(
                street: faker.address.streetName(),
                postalCodeSuffix: String(
                    letters.randomSample(count: 2)
                ),
                houseNumber: faker.number.randomInt(
                    min: 4,
                    max: 200
                ),
                latitude: latitude,
                longitude: longitude,
                postalAreaID: try postalArea.requireID()
            )
            addresses.append(address)
        }
        try await addresses.create(on: database)
        console.output("Created addresses")

        // Create cuisines
        let cuisines =
            restaurants
            .map({ $0.cuisine })
            .uniqued()
            .map({ Cuisine(name: $0) })
        try await cuisines.create(on: database)
        console.output("Created cuisines")

        // Create business types
        let businessTypeNames = [
            "Bistro", "Brasserie", "Café", "Grand café",
            "Restaurant",
        ]
        let businessTypes = businessTypeNames.map { name in
            BusinessType(name: name)
        }
        try await businessTypes.create(on: database)
        console.output("Created businessTypes")

        // Create businesses
        var progressBar = context.console.progressBar(
            title: "Creating businesses"
        )
        var factor = 1.0 / Double(addresses.count)
        var counter = 0
        progressBar.start()
        for address in addresses {
            let cuisine = cuisines.randomElement()!
            let businessType =
                businessTypes.randomElement()!
            let photo = restaurants.filter({
                $0.cuisine == cuisine.name
            })
            .randomElement()!
            let business = Business(
                name:
                    "\(cuisine.name) \(businessType.name)",
                description: photo.alt,
                deliveryCharge: faker.number.randomInt(
                    min: 2,
                    max: 7
                ) * 50,
                minimumOrderAmount: faker.number.randomInt(
                    min: 1,
                    max: 4
                )
                    * 500,
                addressID: try address.requireID(),
                businessTypeID: try businessType.requireID()
            )

            // Set cuisine.
            try await business.create(on: database)
            try await business.$cuisines.attach(
                [cuisine],
                on: database
            )

            // Set opening hours.
            let businessID = try business.requireID()
            let closedWeekday = faker.number.randomInt(
                min: 1,
                max: 7
            )
            let weekdays: [Int] = Array(1...7)
            var startTime =
                60
                * faker.number.randomInt(min: 16, max: 18)
            var endTime =
                60
                * faker.number.randomInt(min: 22, max: 23)
            if businessType.name == "Bistro" {
                startTime =
                    60
                    * faker.number.randomInt(
                        min: 10,
                        max: 14
                    )
                endTime =
                    60
                    * faker.number.randomInt(
                        min: 18,
                        max: 20
                    )
            }

            for weekday in weekdays {
                let hours = OpeningHours(
                    weekday: weekday,
                    startTime: startTime,
                    endTime: endTime,
                    isClosed: weekday == closedWeekday,
                    businessID: businessID
                )
                try await hours.create(on: database)
            }
            try await business.save(on: database)

            progressBar.activity.currentProgress =
                factor * Double(counter)
            counter += 1
        }
        progressBar.succeed()

        let combo = ProductType(name: "Combo")
        try await combo.save(on: database)

        let businesses: [Business] =
            try await Business.query(on: database)
            .with(\.$cuisines)
            .with(\.$products)
            .with(\.$address) { a in
                a.with(\.$postalArea) { p in
                    p.with(\.$city)
                }
            }
            .all()

        // Create all of the relations.
        progressBar = context.console.progressBar(
            title: "Adding a lot of relations"
        )
        factor = 1.0 / Double(businesses.count)
        counter = 0
        progressBar.start()

        for business in businesses {
            // Add products to business.
            let cuisines = business.cuisines
            let products =
                try dishes
                .filter({
                    $0.cuisine == cuisines.first?.name
                })
                .compactMap { dish in
                    if let productType = productTypes.first(
                        where: {
                            $0.name == dish.dishtype
                        })
                    {
                        return Product(
                            name: productType.name,
                            description: dish.alt,
                            price: (faker.number.randomInt(
                                min: 3,
                                max: 21
                            )
                                * 100) + 99,
                            businessID:
                                try business.requireID(),
                            productTypeID:
                                try productType.requireID()
                        )
                    }

                    return nil
                }
            try await products.create(on: database)

            // Add a discount to some of the products.
            let percentage =
                faker.number.randomInt(min: 1, max: 4) * 10
            let discount = Discount(
                name: "\(percentage)% Off",
                percentage: percentage,
                businessID: try business.requireID(),
                onlineDate: faker.date.backward(days: 1),
                offlineDate: faker.date.forward(13)
            )
            try await discount.create(on: database)
            let discounted =
                try products
                .filter({ _ in
                    faker.number.randomInt(min: 1, max: 7)
                        == 3
                }).map { product in
                    ProductDiscount(
                        productID: try product.requireID(),
                        discountID: try discount.requireID()
                    )
                }
            try await discounted.create(on: database)

            // Add combo products (which hold other products).
            let usedProductTypeIds =
                products
                .map(\.$productType.id)
                .uniqued()
                .compactMap({ $0 })

            for cuisine in cuisines {
                for i in 1...3 {
                    let children =
                        usedProductTypeIds
                        .randomSample(count: 3)
                        .compactMap({ productType in
                            products.first(where: {
                                $0.$productType.id
                                    == productType
                            })
                        })

                    let total = children.map(\.price)
                        .reduce(0, +)
                    let parent = Product(
                        name: "Combo \(i)",
                        description:
                            "\(cuisine.name) combo",
                        price: total - 300,
                        businessID:
                            try business.requireID(),
                        productTypeID: try combo.requireID()
                    )
                    try await parent.create(on: database)
                    try await parent.$products.attach(
                        children,
                        on: database
                    )
                    try await parent.save(on: database)
                }
            }

            // Create some customers in the same city as the business.
            var customers: [Customer] = []
            let randomAreas = postalAreas.filter({
                $0.$city.id
                    == business.address.postalArea.city.id
            }).randomSample(count: 2)
            for postalArea in randomAreas {
                // Create customer.
                let firstName = faker.name.firstName()
                let lastName = faker.name.lastName()
                let domain = faker.internet.domainName(true)
                let email =
                    "\(firstName.lowercased()).\(lastName.lowercased()).\(postalArea.postalCode)@\(domain)"
                let customer = Customer(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    telephone:
                        "06\(faker.number.randomInt(min: 12_345_678, max: 98_765_432))"
                )
                try await customer.create(on: database)

                // Add one address to each customer.
                let address = Address(
                    street: faker.address.streetName(),
                    postalCodeSuffix: String(
                        letters.randomSample(count: 2)
                    ),
                    houseNumber: faker.number.randomInt(
                        min: 4,
                        max: 200
                    ),
                    latitude: postalArea.latitude,
                    longitude: postalArea.longitude,
                    postalAreaID: try postalArea.requireID()
                )
                try await address.save(on: database)
                try await customer.$addresses.attach(
                    [address],
                    on: database
                )
                try await customer.save(on: database)
                customers.append(customer)

                // Create courier for this customer.
                let courier = Courier(
                    firstName: faker.name.firstName(),
                    lastName: faker.name.lastName(),
                    telephone:
                        "06\(faker.number.randomInt(min: 12_345_678, max: 98_765_432))"
                )
                try await courier.save(on: database)

                // Add some orders for every customer.
                let localBusinesses =
                    businesses
                    .filter { business in
                        business.address.postalArea.$city.id
                            == postalArea.$city.id
                    }
                    .randomSample(count: 2)

                for business in localBusinesses {
                    // Create order.
                    let order = Order(
                        customerID:
                            try customer.requireID(),
                        businessID:
                            try business.requireID(),
                        addressID: try address.requireID()
                    )
                    let createdAt = faker.date.backward(
                        days: faker.number.randomInt(
                            min: 3,
                            max: 21
                        )
                    ).addingTimeInterval(
                        faker.number.randomDouble(
                            min: 0,
                            max: 60
                        ) * 120.0
                    )
                    let sentAt =
                        createdAt.addingTimeInterval(
                            20.0 * 60
                        )
                    order.createdAt = createdAt
                    order.$courier.id = courier.id
                    order.preparedAt =
                        createdAt.addingTimeInterval(
                            5.0 * 60
                        )
                    order.sentAt = sentAt
                    order.deliveredAt =
                        createdAt.addingTimeInterval(
                            30.0 * 60
                        )
                    try await order.save(on: database)
                    order.createdAt = createdAt
                    try await order.save(on: database)

                    // Add products to order.
                    let selection = products.randomSample(
                        count: 5
                    )
                    for product in selection {
                        let orderedProduct = ProductOrder(
                            quantity: faker.number
                                .randomInt(min: 1, max: 4),
                            price: product.price,
                            productID:
                                try product.requireID(),
                            orderID: try order.requireID()
                        )
                        try await orderedProduct.save(
                            on: database
                        )
                    }

                    // Add review for every order.
                    let review = BusinessReview(
                        review: faker.lorem.paragraph(
                            sentencesAmount: 2
                        ),
                        rating: Double(
                            faker.number.randomInt(
                                min: 1,
                                max: 5
                            )
                        ),
                        isAnonymous: faker.number
                            .randomBool(),
                        businessID:
                            try business.requireID(),
                        customerID:
                            try customer.requireID(),
                        orderID: try order.requireID()
                    )
                    try await review.save(on: database)

                    // Add small chat conversation for every order.
                    for i in 0...3 {
                        let chat = Chat(
                            orderID: try order.requireID(),
                            customerID:
                                try customer.requireID(),
                            courierID:
                                try courier.requireID(),
                            message: faker.lorem.sentence(),
                            sender: i % 2 == 0
                                ? .customer : .courier
                        )

                        try await chat.save(on: database)
                        chat.createdAt =
                            sentAt.addingTimeInterval(
                                Double(i + 2) * 60
                            )
                        chat.seenAt =
                            i < 3
                            ? sentAt.addingTimeInterval(
                                Double(i + 3) * 60
                            )
                            : nil
                        try await chat.save(on: database)
                    }
                }
            }

            progressBar.activity.currentProgress =
                factor * Double(counter)
            counter += 1
        }
        progressBar.succeed()
    }
}
