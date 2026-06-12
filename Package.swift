// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchTodo",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "NotchTodoCore", targets: ["NotchTodoCore"]),
        .executable(name: "NotchTodo", targets: ["NotchTodoApp"]),
        .executable(
            name: "NotchTodoWidgetExtension",
            targets: ["NotchTodoWidgetExtension"]
        ),
    ],
    targets: [
        .target(name: "NotchTodoCore"),
        .executableTarget(
            name: "NotchTodoApp",
            dependencies: ["NotchTodoCore"]
        ),
        .executableTarget(
            name: "NotchTodoWidgetExtension",
            dependencies: ["NotchTodoCore"],
            swiftSettings: [
                .unsafeFlags(["-application-extension"], .when(platforms: [.macOS])),
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("WidgetKit"),
            ]
        ),
        .testTarget(
            name: "NotchTodoCoreTests",
            dependencies: ["NotchTodoCore"]
        ),
        .testTarget(
            name: "NotchTodoAppTests",
            dependencies: ["NotchTodoApp", "NotchTodoCore"]
        ),
    ]
)
