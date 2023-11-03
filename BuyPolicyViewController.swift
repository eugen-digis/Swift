import UIKit
import PassKit

protocol BuyPolicyViewControllerInput: BuyPolicyPresenterOutput {
}

protocol BuyPolicyViewControllerOutput {
    func prepareView(quote: Quote)
    func getBreakdown()
    func startCardFlow()
    func cardNumberChanged(value: String?)
    func cardExpirationChanged(value: String?)
    func cardCvvChanged(value: String?)
    func cardHolderChanged(value: String?)
    func toggleShouldSaveCard()
    func payWithSavedCard()
    func getPolicy(quote: Quote, isFirstPoll: Bool?)
    func selectSavedCard(paymentMethod: DayinsurePaymentMethod)
}

final class BuyPolicyViewController: BaseViewController {
    
    var quote: Quote?
    var quoteSummaryType: QuoteSummaryType = .new
    //MARK: - Private property
    private var output: BuyPolicyViewControllerOutput!
    private var router: BuyPolicyRouter!
    private var viewModel: BuyPolicyViewModel?
    private var timerForShowScrollIndicator: Timer?
    private let underlineAttribute: [NSAttributedString.Key: Any] = [ .underlineStyle: NSUnderlineStyle.single.rawValue]
    //MARK: - Outlets
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var regNumberLabel: UILabel!
    @IBOutlet private weak var vehicleModelLabel: UILabel!
    @IBOutlet private weak var savedCardsView: UIView!
    @IBOutlet private weak var savedCardsViewHeightConstr: NSLayoutConstraint!
    @IBOutlet private weak var savedCardsCollectionView: UICollectionView!
    @IBOutlet private weak var cardNumberField: DITextField!
    @IBOutlet private weak var cardHolderField: DITextField!
    @IBOutlet private weak var cardExpirationField: DITextField!
    @IBOutlet private weak var cvvField: DITextField!
    @IBOutlet private weak var saveThisCardView: UIView!
    @IBOutlet private weak var saveCardImage: UIImageView!
    @IBOutlet private weak var saveThisCardViewHeightConstr: NSLayoutConstraint!
    @IBOutlet private weak var clearCardView: UIView!
    @IBOutlet private weak var clearCardButton: UIButton!
    @IBOutlet private weak var clearCardViewHeightConstr: NSLayoutConstraint!
    @IBOutlet private weak var totalPriceLabel: UILabel!
    @IBOutlet private weak var breakdownButton: UIButton!
    @IBOutlet private weak var payButton: DIButton!
    @IBOutlet private weak var saveCardButton: UIButton!
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        BuyPolicyConfigurator.shared.configure(viewController: self)
    }
    //MARK: - Livecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController(exitAction: router.routeToStart)
        setupView()
        if let quote = quote {
            output.prepareView(quote: quote)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTimerForShowScrollIndicator()
    }
}

private extension BuyPolicyViewController {
    //MARK: - Objc methods
    @objc func breakdownButtonClicked() {
        guard ReachabilityService.instance.currentStatus == .reachable else {
            showOfflineError()
            return
        }
        output.getBreakdown()
    }
    
    @objc func payButtonClicked() {
        if viewModel?.savedPaymentMethod != nil {
            output.payWithSavedCard()
        } else {
            output.startCardFlow()
        }
    }
    
    @objc func saveCardButtonClicked() {
        output.toggleShouldSaveCard()
    }
    
    @objc func clearCardDetailsClicked() {
        if let method = viewModel?.savedPaymentMethod {
            updateViewForCleaning()
            output.selectSavedCard(paymentMethod: method)
        } else {
            updateViewForCleaning()
            output.cardCvvChanged(value: nil)
        }
    }
    
    @objc func showScrollIndicatorsInContacts() {
        UIView.animate(withDuration: 0.001) { [weak self] in
            self?.scrollView.flashScrollIndicators()
        }
    }
    //MARK: - UI methods

    func setupView() {
        setupCardNumberField()
        setuCvvField()
        setuCardExpirationField()
        setuCardHolderField()
        savedCardsCollectionView.backgroundColor = .clear
        saveThisCardView.isHidden = false
        clearCardView.isHidden = true
        savedCardsCollectionView.delegate = self
        savedCardsCollectionView.dataSource = self
        savedCardsCollectionView.showsVerticalScrollIndicator = false
        savedCardsCollectionView.showsHorizontalScrollIndicator = false
        clearCardButton.setAttributedTitle(NSAttributedString(string: (clearCardButton.titleLabel?.text)!, attributes: underlineAttribute), for: .normal)
        breakdownButton.addTarget(self, action: #selector(breakdownButtonClicked), for: .touchUpInside)
        payButton.addTarget(self, action: #selector(payButtonClicked), for: .touchUpInside)
        saveCardButton.addTarget(self, action: #selector(saveCardButtonClicked), for: .touchUpInside)
        clearCardButton.addTarget(self, action: #selector(clearCardDetailsClicked), for: .touchUpInside)
    }
    
    func setupCardNumberField() {
        cardNumberField.textContentType = .creditCardNumber
        cardNumberField.name = "Card number"
        cardNumberField.prefixImg = UIImage(named: "card")
        cardNumberField.keyboardType = .numberPad
        cardNumberField.delegate = self
    }
    
    func setuCvvField() {
        cvvField.name = "CVV security code"
        cvvField.prefixImg = UIImage(named: "lock")
        cvvField.keyboardType = .numberPad
        cvvField.delegate = self
    }
    
    func setuCardExpirationField() {
        cardExpirationField.name = "Expiry date (mm/yy)"
        cardExpirationField.prefixImg = UIImage(named: "calendar")
        cardExpirationField.keyboardType = .numberPad
        cardExpirationField.delegate = self
    }
    
    func setuCardHolderField() {
        cardHolderField.textContentType = .name
        cardHolderField.name = "Name on card"
        cardHolderField.prefixImg = UIImage(named: "user")
        cardHolderField.delegate = self
    }
    
    func updateViewForCleaning() {
        cardNumberField.setText(value: nil)
        cardHolderField.setText(value: nil)
        cardExpirationField.setText(value: nil)
        cvvField.setText(value: nil)
        cardNumberField.textField.isEnabled = true
        cardExpirationField.textField.isEnabled = true
        cardHolderField.textField.isEnabled = true
        clearCardView.isHidden = true
        saveThisCardView.isHidden = false
    }
    
    func startTimerForShowScrollIndicator() {
        timerForShowScrollIndicator =
            Timer.scheduledTimer(timeInterval: 0.3, 
                                 target: self,
                                 selector: #selector(showScrollIndicatorsInContacts), userInfo: nil,
                                 repeats: true)
    }
    
    func refreshViewModel() {
        regNumberLabel.text = viewModel?.regNumber
        vehicleModelLabel.text = viewModel?.vehicleModel
        
        savedCardsViewHeightConstr.constant = viewModel?.paymentMethods.count == 0 ? -20 : 186
        savedCardsView.isHidden = viewModel?.paymentMethods.count == 0
        totalPriceLabel.attributedText = NSAttributedString().attributedPriceText(price: viewModel?.totalPrice)
        breakdownButton.isHidden = viewModel?.breakdownButtonHidden != false
        
        if viewModel?.viewMode == .savedCards {
            if let paymentMethod = viewModel?.savedPaymentMethod {
                cardNumberField.setText(value: "XXXX XXXX XXXX \(paymentMethod.lastFour!)")
                cardExpirationField.setText(value: "\(paymentMethod.expiryMonth!)/\(paymentMethod.expiryYear.suffix(2))")
                cardHolderField.setText(value: "\(paymentMethod.holderName!)")
                cardNumberField.textField.isEnabled = false
                cardExpirationField.textField.isEnabled = false
                cardHolderField.textField.isEnabled = false
                clearCardView.isHidden = false
                saveThisCardView.isHidden = true
            } else {
                updateViewForCleaning()
            }
        }
        savedCardsCollectionView.reloadData()
        
        if let error = viewModel?.cardNumberError {
            cardNumberField.errorText = error
            cardNumberField.hasError = true
        } else {
            cardNumberField.hasError = false
        }
        
        if let error = viewModel?.cardCvvError {
            cvvField.errorText = error
            cvvField.hasError = true
        } else {
            cvvField.hasError = false
        }
        
        if let error = viewModel?.cardExpirationError {
            cardExpirationField.errorText = error
            cardExpirationField.hasError = true
        } else {
            cardExpirationField.hasError = false
        }
        
        if let error = viewModel?.cardHolderError {
            cardHolderField.errorText = error
            cardHolderField.hasError = true
        } else {
            cardHolderField.hasError = false
        }
        
        payButton.isEnabled = viewModel?.isFormValid == true
        saveCardImage.image = viewModel?.saveCardCheckboxImage
        
    }
}

extension BuyPolicyViewController: BuyPolicyViewControllerInput {
    func hide3dsComponent() {
        if let vc = presentedViewController {
            vc.dismiss(animated: false, completion: nil)
        }
    }
    
    func showViewModel(viewModel: BuyPolicyViewModel) {
        self.viewModel = viewModel
        refreshViewModel()
    }
    
    func showBreakdown(quote: Quote) {
        router.routeToBreakdown(quote: quote, quoteSummaryType: quoteSummaryType)
    }
    
    func showPolicy(policy: Policy) {
        guard let regNumber = viewModel?.regNumber else { return }
        router.routeToPolicy(policy: policy, regNumber: regNumber)
    }
    
    func showPolicyPreparation() {
        router.routeToPolicyPreparation()
    }
    
    func showPolicyPreparationFailed(quote: Quote, error: APIError) {
        router.routeToPolicyPreparationFailed(quote: quote, error: error)
    }
    
    func showPaymentIssue(quote: Quote, message: String?, invalidQuote: Bool?, url: String?, error: APIError?) {
        router.routeToPaymentProviderIssue(quote: quote, message: message, invalidQuote: invalidQuote, url: url, error: error)
    }
}

extension BuyPolicyViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.paymentMethods.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithRegistration(type: SavedPayCardCell.self, indexPath: indexPath)
        guard let card = viewModel?.paymentMethods[indexPath.row] else { return UICollectionViewCell() }
        cell.deleteButton.isHidden = true
        cell.fill(card: card)
        cell.selectAction = { [weak self] in
            self?.output.selectSavedCard(paymentMethod: card)
            self?.cvvField.setText(value: nil)
            self?.output.cardCvvChanged(value: nil)
        }
        if card == viewModel?.savedPaymentMethod {
            cell.updateAsSelected()
        } else {
            cell.updateAsDeselected()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 239, height: 126)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
}

extension BuyPolicyViewController: DITextFieldDelegate {
    
    func textChanged(text: String?, view: DITextField) {
        switch view {
        case cardNumberField:
            if viewModel?.cardNumber != "" && viewModel?.cardNumber != nil && text == "" && cardNumberField.textField.text?.count == 0 {
                cardNumberField.isChanged = true
            }
            output.cardNumberChanged(value: text)
        case cvvField:
            if viewModel?.cardCvv != "" && viewModel?.cardCvv != nil && text == "" && cvvField.textField.text?.count == 0 {
                cvvField.isChanged = true
            }
            output.cardCvvChanged(value: text)
        case cardExpirationField:
            if viewModel?.cardExpiration != "" && viewModel?.cardExpiration != nil && text == "" && cardExpirationField.textField.text?.count == 0 {
                cardExpirationField.isChanged = true
            }
            output.cardExpirationChanged(value: text)
        case cardHolderField:
            if viewModel?.cardHolder != "" && viewModel?.cardHolder != nil && text == "" && cardHolderField.textField.text?.count == 0 {
                cardHolderField.isChanged = true
            }
            output.cardHolderChanged(value: text)
        default: ()
        }
    }
    
    func textField(_ view: DITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        guard let text = view.textField.text, text.count > 0 else {
            return true
        }
        
        switch view {
        case cardNumberField:
            if string == "" {
                if text.count > 4, text[text.count - 2] == " " {
                    let newText = text.dropLast(2)
                    view.setText(value: String(newText))
                    output.cardNumberChanged(value: String(newText))
                    return false
                }
                return true
            }
            
            if text.count >= 19 + 4 {
                return false
            }
            
            if Int(string) == nil {
                return false
            }
            
            if text.replacingOccurrences(of: " ", with: "").count % 4 == 0, !(string == "") {
                if let newText = view.textField?.text {
                    view.setText(value: newText + " ")
                }
            }
            return true
            
        case cvvField: return !(text.count == 4 && string.count > range.length)
            
        case cardExpirationField:
            if view.textField.text?.count == 2, !(string == "") {
                view.setText(value: text + "/")
            }
            
            return !(text.count > 4 && string.count > range.length)
            
        default: return true
        }
    }
}

extension BuyPolicyViewController: RefusalPopupViewControllerDelegate {
    func tryAgainButtonClicked() {
        if router.errorStatusCode == 404 {
            router.routeToStart()
        } else {
            router.routeBackToCardPay()
        }
    }
    
    func cancelButtonClicked() {
        // no needed here
    }
}

extension BuyPolicyViewController: PaymentProviderIssueViewControllerDelegate {
    func quoteWasChanged() {
        router.routeToQuote()
    }
    
    func policyAlreadyPurchased() {
        router.routeHome()
    }
}
