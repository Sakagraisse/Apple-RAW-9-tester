import Foundation

guard CommandLine.arguments.count >= 6,
      CommandLine.arguments.count.isMultiple(of: 2) else {
    fatalError("Usage: package_icns.swift output.icns type image.png [type image.png ...]")
}

func fourCC(_ value: String) -> Data {
    precondition(value.utf8.count == 4)
    return Data(value.utf8)
}

func bigEndian(_ value: UInt32) -> Data {
    var encoded = value.bigEndian
    return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
var chunks = Data()

for index in stride(from: 2, to: CommandLine.arguments.count, by: 2) {
    let type = CommandLine.arguments[index]
    let imageURL = URL(fileURLWithPath: CommandLine.arguments[index + 1])
    let image = try Data(contentsOf: imageURL)

    chunks.append(fourCC(type))
    chunks.append(bigEndian(UInt32(image.count + 8)))
    chunks.append(image)
}

var icon = Data()
icon.append(fourCC("icns"))
icon.append(bigEndian(UInt32(chunks.count + 8)))
icon.append(chunks)
try icon.write(to: outputURL, options: .atomic)
