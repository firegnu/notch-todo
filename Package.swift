// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchTodo",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "NotchTodoCore", targets: ["NotchTodoCore"]),
        .executable(name: "NotchTodo", targets: ["NotchTodoApp"]),
    ],
    targets: [
        .target(name: "NotchTodoCore"),
        .executableTarget(
            name: "NotchTodoApp",
            dependencies: ["NotchTodoCore"]
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
