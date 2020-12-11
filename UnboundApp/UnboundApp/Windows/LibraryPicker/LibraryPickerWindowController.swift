import Foundation

@objc class LibraryPickerWindowController: NSWindowController, NSOpenSavePanelDelegate {
    @IBAction func chooseFolder(_: Any) {
        if PIXFileParser.shared().userChooseFolderDialog() {
            close()
        }
    }

    @objc class func create() -> LibraryPickerWindowController {
        LibraryPickerWindowController(windowNibName: "LibraryPickerWindowController")
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
