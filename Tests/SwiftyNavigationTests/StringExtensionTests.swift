import Testing
import SwiftyNavigation

struct StringExtensionTests {

    @Test
    func addParameterTests() {
        let path = "/a/path"
        #expect(path.add(parameters: ["number": "45"]) == "/a/path?number=45")
    }

    @Test
    func addSingleParameterTests() {
        let path = "/a/path"
        #expect(path.add(parameter: "number", with: "45") == "/a/path?number=45")
    }

    @Test
    func getParametersTests() {
        let string = "/a/path?number=45"
        #expect(string.getParameters()["number"] == "45")
    }

    @Test
    func getPathWithOutParameters() {
        let string = "/a/path?number=45"
        #expect(string.pathWithOutParameters() == "/a/path")
    }
}
