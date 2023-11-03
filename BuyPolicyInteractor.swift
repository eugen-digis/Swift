import Foundation
import PassKit
import Adyen
import FirebaseAnalytics

protocol BuyPolicyInteractorInput: BuyPolicyViewControllerOutput {}

protocol BuyPolicyInteractorOutput: BasePresenter {
    func presentQuote(quote: Quote)
    func presentBreakdown(quote: Quote)
    func presentPolicy(policy: Policy)
    func presentPolicyPreparation()
    func presentPolicyPreparationFailed(quote: Quote, error: APIError)
    func presentPaymentIssue(quote: Quote, message: String?, invalidQuote: Bool?, url: String?, error: APIError? )
    func presentCardNumber(value: String?)
    func presentCardExpiration(value: String?)
    func presentCardCvv(value: String?)
    func presentCardHolder(value: String?)
    func presentShouldSaveCard(shouldSaveCard: Bool)
    func presentPaymentMethods(paymentMethods: [DayinsurePaymentMethod])
    func presentSavedCard(paymentMethod: DayinsurePaymentMethod?)
    func dismiss3dsComponent()
}

final class BuyPolicyInteractor: NSObject {

    let output: BuyPolicyInteractorOutput
    var quote: Quote?
    var savedPaymentMethod: DayinsurePaymentMethod?
    var paymentFlowHelper = PaymentFlowHelper()

    private var pollingTimer: Timer?
    private var operationInProcess = false
    private var pollingStartedAt: Date?
    private let PAYMENT_PROVIDER_ERROR_CODE = 503
    private var card = CardEncryptor.Card()
    private var cardHolder: String?
    private var shouldSaveCard  = false
    
    init(output: BuyPolicyInteractorOutput) {
        self.output = output
    }
}

extension BuyPolicyInteractor: BuyPolicyInteractorInput {
    
    func getPaymentMethods(quote: Quote) {
        if operationInProcess { return }
        operationInProcess = true

        output.displaySpinner()
        
        if let policyId = quote.policyId, quote.isAmendmentQuote {
            NetworkService.instance.quotes.getPaymentMethods(quote: quote, policyId: policyId) { [weak self] response in
                guard let self = self else { return }
                
                self.operationInProcess = false
                self.output.hideSpinner()
                
                if let error = response.error {
                    self.output.presentError(error: error)
                    return
                }
                
                self.output.presentPaymentMethods(paymentMethods: response.paymentMethods ?? [])
            }
        } else {
            NetworkService.instance.quotes.getPaymentMethods(quote: quote) { [weak self] response in
                guard let self = self else { return }
                
                self.operationInProcess = false
                self.output.hideSpinner()
                
                if let error = response.error {
                    self.output.presentError(error: error)
                    return
                }
                
                self.output.presentPaymentMethods(paymentMethods: response.paymentMethods ?? [])
            }
        }
    }
    
    func getPolicy(quote: Quote, isFirstPoll: Bool?) {
        paymentFlowHelper.getPolicy(quote: quote, isFirstPoll: isFirstPoll ?? true)
    }
    
    func selectSavedCard(paymentMethod: DayinsurePaymentMethod) {  
        if savedPaymentMethod == paymentMethod {
             savedPaymentMethod = nil
        } else {
             savedPaymentMethod = paymentMethod
        }
        output.presentSavedCard(paymentMethod: savedPaymentMethod)
    }
    
    func payWithSavedCard() {
        guard let quote = quote, let paymentMethod = savedPaymentMethod else { return }
        
        if operationInProcess { return }
        operationInProcess = true

        output.displaySpinner()
        NetworkService.instance.quotes.purchase(quote: quote, paymentMethod: paymentMethod) { [weak self] response in
            guard let self = self else { return }

            self.output.hideSpinner()
            self.operationInProcess = false
            if let error = response.error,
               error.isRefreshToken {
                self.output.presentError(error: error)
                return
            }
            self.paymentFlowHelper.handlePaymentResponse(quote: quote, response: response)
        }
    }
    
    func toggleShouldSaveCard() {
        shouldSaveCard = !shouldSaveCard
        output.presentShouldSaveCard(shouldSaveCard: shouldSaveCard)
    }
    
    func cardNumberChanged(value: String?) {
        card.number = value
        output.presentCardNumber(value: value)
    }
    
    func cardExpirationChanged(value: String?) {
        let components = value?.split(separator: "/") ?? []
        card.expiryMonth = components.count > 0 ? String(components[0]): nil
        card.expiryYear = components.count > 1 ? "20\(String(components[1]))": nil
        output.presentCardExpiration(value: value)
    }
    
    func cardCvvChanged(value: String?) {
        card.securityCode = value
        output.presentCardCvv(value: value)
    }
    
    func cardHolderChanged(value: String?) {
        cardHolder = value
        output.presentCardHolder(value: value)
    }
    
    func startCardFlow() {
        guard let quote = quote else { return }
        
        guard let encryptedCard = try? CardEncryptor.encryptedCard(for: card, publicKey: DIConstants.shared.adyenPublicKey) else {
            output.presentError(message: "Unable to process the card")
            return
        }
        
        if operationInProcess { return }
        operationInProcess = true

        output.displaySpinner()
        NetworkService.instance.quotes.purchase(quote: quote, card: encryptedCard, cardHolder: cardHolder, shouldSaveCard: shouldSaveCard) { [weak self] response in
            guard let self = self else { return }

            self.output.hideSpinner()
            self.operationInProcess = false
            if let error = response.error,
               error.isRefreshToken {
                self.output.presentError(error: error)
                return
            }
            self.paymentFlowHelper.handlePaymentResponse(quote: quote, response: response)
        }
    }
    
    func getBreakdown() {
        guard let quote = quote else { return }
        output.presentBreakdown(quote: quote)
    }
    
    func prepareView(quote: Quote) {
        quote = quote
        paymentFlowHelper.delegate = self
        output.presentQuote(quote: quote)
        getPaymentMethods(quote: quote)
    }

}

extension BuyPolicyInteractor: PaymentFlowHelperDelegate {
    func dismiss3dsComponent() {
        output.dismiss3dsComponent()
    }
     
    func presentPolicyPreparationFailed(quote: Quote, error: APIError) {
        output.presentPolicyPreparationFailed(quote: quote, error: error)
    }
    
    func presentPolicy(policy: Policy) {
        output.presentPolicy(policy: policy)
    }
    
    func presentPolicyPreparation() {
        output.presentPolicyPreparation()
    }
    
    func presentPaymentIssue(quote: Quote, message: String?, invalidQuote: Bool?, url: String?, error: APIError?) {
        output.presentPaymentIssue(quote: quote, message: message, invalidQuote: invalidQuote, url: url, error: error)
    }
    
    func displaySpinner() {
        output.displaySpinner()
    }
    
    func hideSpinner() {
        output.hideSpinner()
    }

}
