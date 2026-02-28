import SourceKittenFramework

public struct SKClient {
    /// file path or temp path.
    public let path: String
    /// snapshot code by ``path``.
    public let code: String
    public let arguments: [String]
    
    public init(path: String, sdk: SDK = .macosx) throws {
        let arguments: [String] = sdk.pathArgs + [path]
        try self.init(path: path, arguments: arguments)
    }
    
    public init(path: String, arguments: [String]) throws {
        let code = try String(contentsOfFile: path, encoding: .utf8)
        self.init(path: path, code: code, arguments: arguments)
    }
    
    private static let codePath = "code: /temp.swift"
    public init(code: String, sdk: SDK = .macosx) {
        let arguments: [String] = sdk.pathArgs
        self.init(path: Self.codePath, code: code, arguments: arguments + [Self.codePath])
    }
    
    public init(code: String, arguments: [String]) {
        self.init(path: Self.codePath, code: code, arguments: arguments + [Self.codePath])
    }
    
    public init(path: String, code: String, arguments: [String]) {
        self.path = path
        self.code = code
        self.arguments = arguments
    }
    
//    public static func module() -> SKClient {
//        
//    }
    
    public typealias SourceKitResponse = [String : SourceKitRepresentable]
    public func cursorInfo(_ offset: Int) throws -> SourceKitResponse {
        let raw: SourceKitResponse = try Request.customRequest(request: [
            "key.request": UID("source.request.cursorinfo"),
            "key.name": path,
            "key.sourcefile": path,
            "key.sourcetext": code,
            "key.offset": Int64(offset),
            "key.compilerargs": arguments

        ]).send()
        return raw
    }
    
    @discardableResult
    public func editorOpen() throws -> SourceKitResponse {
        let raw: SourceKitResponse = try Request.customRequest(request: [
            "key.request": UID("source.request.editor.open"),
            "key.name": path,
            "key.sourcetext": code,
            "keys.compilerargs": arguments
        ]).send()
        return raw
    }
    
//    public func editorOpen() throws -> SourceKitResponse{
//        let raw: [String : SourceKitRepresentable] = try Request.editorOpen(file: File(path: path)!).send()
//        return SourceKitResponse(raw)
//    }

    @discardableResult
    public func editorClose() throws -> SourceKitResponse {
        let raw: SourceKitResponse = try Request.customRequest(request: [
            "key.request": UID("source.request.editor.close"),
            "key.name": path,
//            "key.sourcefile": path,
//            "keys.compilerargs": arguments
        ]).send()
        return raw
    }
}
