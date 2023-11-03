import Foundation
import Adyen

final class BuyPolicyViewModel {
    
    enum ViewMode { case card, savedCards }
    var savedPaymentMethod: DayinsurePaymentMethod?
    var cardNumber: String?
    var cardHolder: String?
    var cardCvv: String?
    var cardExpiration: String?
    var shouldSaveCard = false
    var paymentMethods: [DayinsurePaymentMethod] = []
    var viewMode: ViewMode?
    var quote: Quote?
     
    private let cardValidator = CardNumberValidator()
    private let expiryValidator = CardExpiryDateValidator()
    private let securityCodeValidator = CardSecurityCodeValidator()
    private let pleaseCheck = "Please check this"
    private let thisIsRequired = "This is required"

    func setQuote(quote: Quote) {
        self.quote = quote
    }
    
    var regNumber: String {
        guard let quote = quote,
              let regNumber = quote.quoteAssets?.first?.properties.vehicleRegistration else {
            return "Reg number"
        }
        return regNumber
    }
    var vehicleModel: String {
        var makeAndModel = ""
        
        if let make = quote?.quoteAssets?.first?.properties.vehicleMake {
            makeAndModel.append(make)
        }
        if let model = quote?.quoteAssets?.first?.properties.vehicleModel {
            makeAndModel.append(makeAndModel == "" ? model : " \(model)")
        }
        
        return makeAndModel
    }
    var saveCardCheckboxImage: UIImage? {
        return shouldSaveCard ? UIImage(named: "select-new"): UIImage(named: "deselect-new")
    }

    func setPaymentMethods(paymentMethods: [DayinsurePaymentMethod]) {
        self.paymentMethods = paymentMethods
    }

    var cardNumberError: String? {
        guard let cardNumber = cardNumber, cardNumber.count > 0 else { return thisIsRequired }
        guard cardNumber.count <= 19 + 4 else { return pleaseCheck }
        if cardValidator.isValid(cardNumber) { return nil }
        return pleaseCheck
    }
    
    var cardNumberValid: Bool {
        guard let cardNumber = cardNumber, cardValidator.isValid(cardNumber), cardNumber.count <= 19 + 4 else { return false }
        return cardValidator.isValid(cardNumber)
    }
    
    var cardHolderError: String? {
        guard let cardHolder = cardHolder, cardHolder.count > 0 else { return thisIsRequired }
        guard cardHolder.count >= 2, cardHolder.count <= 60 else {
            return pleaseCheck
        }
        guard cardHolder.first != " ", cardHolder.last != " ", !cardHolder.contains("  ") else { return pleaseCheck }
        return nil
    }
    
    var cardHolderValid: Bool {
        guard let cardHolder = cardHolder, cardHolder.count >= 2, cardHolder.count <= 60 else { return false }
        guard cardHolder.first != " ", cardHolder.last != " ", !cardHolder.contains("  ") else { return false }
        return NSPredicate(format: "SELF MATCHES %@", "^(([^ ]?)(^[a-zA-Z].*[a-zA-Z]$)([^ ]?))$").evaluate(with: cardHolder)
    }
    
    var cardCvvError: String? {
        guard let cardCvv = cardCvv, cardCvv.count > 0 else { return thisIsRequired }
        if securityCodeValidator.isValid(cardCvv) { return nil }
        return pleaseCheck
    }
    
    var cardCvvValid: Bool {
        guard let cardCvv = cardCvv, securityCodeValidator.isValid(cardCvv) else { return false }
        return true
    }
    
    var cardExpirationError: String? {
        guard let cardExpiration = cardExpiration, cardExpiration.count > 0 else { return thisIsRequired }
        if expiryValidator.isValid(cardExpiration.replacingOccurrences(of: "/", with: "")) { return nil }
        return pleaseCheck
    }
    
    var cardExpirationValid: Bool {
        guard let cardExpiration = cardExpiration else { return false }
        return expiryValidator.isValid(cardExpiration.replacingOccurrences(of: "/", with: ""))
    }

    var isFormValid: Bool {
        return cardNumberValid && cardHolderValid && cardExpirationValid && cardCvvValid || cardCvvValid && savedPaymentMethod != nil
    }
    
    var totalPrice: String? {
        guard let quote = quote, let price = quote.price else { return nil }
        return price.total.toCurrency
    }
    
    var breakdownButtonHidden: Bool {
        guard let price = quote?.price else { return true }
        return price.items.count == 0
    }
    
}
