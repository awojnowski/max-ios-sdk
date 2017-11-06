import Foundation

class MAXErrorReporterStub: MAXErrorReporter {
    var data: Data?
    
    override func record(data: Data) {
        self.data = data
    }
}
