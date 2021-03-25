import Foundation
import ArgumentParser

public struct AllCommands: ParsableCommand {
    public static var cnfiguration = CommandConfiguration(
        commandName: "observepointcli",
        abstract: "A(n) (unofficial) utility for interacting with the ObservePoint API.",
        subcommands: [
        ]
    )
    
    public init() {}
}
