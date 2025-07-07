import SwiftUI
import PythonKit

@main
struct MyApp: App {
    init() {
        PythonLibrary.useLibrary(at: "/opt/miniconda3/envs/swiftpy/lib/libpython3.12.dylib")
        let sys = Python.import("sys")
        print("PythonKit initialized")
        print("sys.version =", sys.version)
        print("sys.executable =", sys.executable)
        
        AppTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            MainHomeView()
        }
    }
}
