
import XCTest
@testable import dayinsure

final class ManualDrivingLicenseViewControllerOutputMock: BasePresenter, ManualDrivingLicenseViewControllerOutput {

    var firstNameChangedCalled = 0
    var lastNameChangedCalled = 0
    var dobChangedCalled = 0
    var licenseNumberChangedCalled = 0
    var updateDrivingLicenseCalled = 0
    var getLicenceTypeCalled = 0
    var prepareViewCalled = 0
    var setOcrDrivingLicenseCalled = 0
    var updateLicenceTypeCalled = 0
    
    func firstNameChanged(value: String?) {
        firstNameChangedCalled += 1
    }
    
    func lastNameChanged(value: String?) {
        lastNameChangedCalled += 1
    }
    
    func dobChanged(value: String?) {
        dobChangedCalled += 1
    }
    
    func licenseNumberChanged(value: String?) {
        licenseNumberChangedCalled += 1
    }
    
    func updateDrivingLicense() {
        updateDrivingLicenseCalled += 1
    }
    
    func getLicenceType() {
        getLicenceTypeCalled += 1
    }
    
    func prepareView() {
        prepareViewCalled += 1
    }
    
    func setOcrDrivingLicense(drivingLicense: DrivingLicense) {
        setOcrDrivingLicenseCalled += 1
    }
    
    func updateLicenceType(licenceType: Person.LicenseType) {
        updateLicenceTypeCalled += 1
    }
    
}

final class ManualDrivingLicenseViewControllerTests: XCTestCase {
        
    func makeSUT() -> ManualDrivingLicenseViewController {
        let sut = ManualDrivingLicenseViewController.instance(.onboarding) as! ManualDrivingLicenseViewController
        sut.loadViewIfNeeded()
        return sut
    }
    
    func test_setupView() throws {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        
        sut.setupView()

        XCTAssertEqual(sut.firstNameField.textContentType, .givenName)
        XCTAssertEqual(sut.firstNameField.autocapitalizationType, .words)
        XCTAssertEqual(sut.firstNameField.name, "First name")
        XCTAssertEqual(sut.firstNameField.prefixImg, UIImage(named: "user"))
        
        XCTAssertEqual(sut.lastNameField.textContentType, .familyName)
        XCTAssertEqual(sut.lastNameField.autocapitalizationType, .words)
        XCTAssertEqual(sut.lastNameField.name, "Last name")
        XCTAssertEqual(sut.lastNameField.prefixImg, UIImage(named: "user"))
        
        XCTAssertEqual(sut.dobField.keyboardType, .numberPad)
        XCTAssertEqual(sut.dobField.name, "Date of birth (dd/mm/yyyy)")
        XCTAssertEqual(sut.dobField.prefixImg, UIImage(named: "calendar"))

        XCTAssertEqual(sut.licenseNumberField.name, "Licence number")
        XCTAssertEqual(sut.licenseNumberField.prefixImg, UIImage(named: "card"))
        XCTAssertNotNil(sut.licenseNumberField.autocapitalizationType)
        XCTAssertNotNil(sut.routeFromSummary)
        XCTAssertNotNil(sut.navStackFromSummary)
        XCTAssertNil(sut.occupationFromSummary)
        
        AccountManager.shared.person = MockedPerson.getInstance()
        sut.setupView()
        XCTAssertEqual(sut.firstNameField.text, AccountManager.shared.person?.firstName)
        XCTAssertEqual(output.firstNameChangedCalled, 1)
        XCTAssertEqual(sut.lastNameField.text, "Wood")
        XCTAssertEqual(output.lastNameChangedCalled, 1)
        XCTAssertEqual(sut.dobField.text, "24/12/1974")
        XCTAssertEqual(output.dobChangedCalled, 1)
        XCTAssertEqual(sut.licenseNumberField.text, "WOOD9DN")
        XCTAssertEqual(output.licenseNumberChangedCalled, 1)
    }
    
    func test_refreshViewModel() throws {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        sut.viewModel = ManualDrivingLicenseViewModel()
        
        sut.refreshViewModel()
        
        XCTAssertNotNil(sut.titleLabel.text)
        sut.firstNameField.setText(value: "Sarah")
        XCTAssertNotNil(sut.viewModel?.firstNameError)
        XCTAssertEqual(sut.firstNameField.hasError, true)
        XCTAssertEqual(sut.firstNameField.errorText, "")
        
        sut.lastNameField.setText(value: "Sarah")
        XCTAssertNotNil(sut.viewModel?.lastNameError)
        XCTAssertEqual(sut.lastNameField.hasError, true)
        XCTAssertEqual(sut.lastNameField.errorText, "")
        
        sut.dobField.setText(value: "Sarah")
        XCTAssertNil(sut.viewModel?.dobError)
        XCTAssertEqual(sut.dobField.hasError, false)
        XCTAssertEqual(sut.dobField.errorText, "")
        
        sut.licenseNumberField.setText(value: "Sarah")
        XCTAssertNotNil(sut.viewModel?.licenseNumberError)
        XCTAssertEqual(sut.licenseNumberField.hasError, true)
        XCTAssertEqual(sut.licenseNumberField.errorText, "")
        
        XCTAssertNotNil(sut.continueButton.isEnabled)
    }
    
    func testViewWillAppear() {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        
        sut.viewWillAppear(false)
        XCTAssertNil(sut.occupationFromSummary)
        XCTAssertNotNil(sut.navStackFromSummary)
        XCTAssertNotNil(sut.routeFromSummary)
    }
    
    func testViewWillDisappear() {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        
        sut.viewWillDisappear(false)
        XCTAssertNotNil(sut)
    }
    
    func test_buttonClicked() throws {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        
        sut.continueButtonClicked(sut.continueButton as Any)
        XCTAssertEqual(output.updateDrivingLicenseCalled, 1)
        
        sut.backButtonClicked((Any).self)
        XCTAssertNotNil(sut)
        
        sut.exitButtonClicked(sut.exitButton as Any)
        XCTAssertNotNil(sut)
    }
    
    func test_methodsViewControllers() throws {
        let sut = makeSUT()
        let output = ManualDrivingLicenseViewControllerOutputMock()
        sut.output = output
        sut.viewModel = ManualDrivingLicenseViewModel()
        
        sut.showLicenseUpdated(person: MockedPerson.getInstance())
        XCTAssertEqual(output.getLicenceTypeCalled, 1)

        sut.textChanged(text: "test", view: sut.firstNameField)
        XCTAssertEqual(output.firstNameChangedCalled, 1)
        
        sut.textChanged(text: "test", view: sut.lastNameField)
        XCTAssertEqual(output.lastNameChangedCalled, 1)
        
        sut.textChanged(text: "test", view: sut.dobField)
        XCTAssertEqual(output.dobChangedCalled, 1)
        
        sut.textChanged(text: "test", view: sut.licenseNumberField)
        XCTAssertEqual(output.licenseNumberChangedCalled, 1)
        
        sut.vehicle = MockedVehicle.getInstance()
        sut.viewModel?.personLicence = MockedLicence.getInstance()
        sut.showLicenseUpdated(person: MockedPerson.getInstance())
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.viewModel?.allLicenceType)
        XCTAssertEqual(sut.viewModel?.allLicenceType?.count, 3)
        XCTAssertNotNil(sut.viewModel?.allLicenceType?.first(where: { $0.type == sut.vehicle.vehicleType?.rawValue}))
        XCTAssertEqual(output.updateLicenceTypeCalled, 0)
        
        sut.showLicenseTypeUpdated(person: MockedPerson.getInstance())
        XCTAssertNotNil(sut)
        
        sut.showPersonLisenceUpdated()
        XCTAssertNotNil(sut)
        XCTAssertEqual(output.updateLicenceTypeCalled, 1)
        
    }
}
