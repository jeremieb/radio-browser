import AppIntents

struct RadioStationAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Radio Station")
    static var defaultQuery = RadioStationEntityQuery()

    var id: String
    var name: String
    var stationImage: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            image: stationImage.map { .init(named: $0) }
        )
    }

    init(id: String, name: String, stationImage: String?) {
        self.id = id
        self.name = name
        self.stationImage = stationImage
    }

    init(from radio: Radio) {
        self.id = radio.id
        self.name = radio.name ?? "Unknown Station"
        self.stationImage = radio.image
    }
}

struct RadioStationEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [RadioStationAppEntity] {
        MyRadios
            .filter { identifiers.contains($0.id) }
            .filter { !($0.disable ?? false) }
            .map { RadioStationAppEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [RadioStationAppEntity] {
        MyRadios
            .filter { !($0.disable ?? false) }
            .map { RadioStationAppEntity(from: $0) }
    }
}

extension RadioStationEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [RadioStationAppEntity] {
        MyRadios
            .filter { !($0.disable ?? false) }
            .filter { ($0.name ?? "").localizedCaseInsensitiveContains(string) }
            .map { RadioStationAppEntity(from: $0) }
    }
}
