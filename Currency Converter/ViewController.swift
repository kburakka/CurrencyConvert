//
//  ViewController.swift
//  Currency Converter
//
//  Created by burak kaya on 06/07/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import Alamofire
import DropDown
import SwiftyJSON

class ViewController: UIViewController,UITextFieldDelegate {

    let latestUrl = "https://api.exchangeratesapi.io/latest"
    var currencies = [String]()
    
    @IBOutlet weak var amount: UITextField! {
        didSet {
            amount?.addDoneCancelToolbar(onDone: (target: self, action: #selector(doneButtonTappedForMyNumericTextField)))
        }
    }
    @IBOutlet weak var toCurrencies: UIButton!
    @IBOutlet weak var fromCurrencies: UIButton!
    @IBOutlet weak var fromCurrency: UILabel!
    @IBOutlet weak var toCurrency: UILabel!
    @IBOutlet weak var fromValue: UILabel!
    @IBOutlet weak var toValue: UILabel!
    @IBOutlet weak var rate: UILabel!
    let dropDown = DropDown()
    @IBOutlet weak var exchange: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        amount.delegate = self
        Alamofire.request(latestUrl, method: .get).responseJSON{ response in
            if response.result.isSuccess
            {
                let sourceJSON : JSON = JSON(response.result.value!)
                let rates = sourceJSON["rates"]
                for (key, _) in rates {
                    self.currencies.append(key)
                }
                self.currencies.sort()
            }
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        exchange.isUserInteractionEnabled = true
        exchange.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let from = fromCurrencies.titleLabel?.text
        let to = toCurrencies.titleLabel?.text
        
        fromCurrencies.setTitle(to, for: .normal)
        toCurrencies.setTitle(from, for: .normal)
        
        fromCurrency.text = "\(to ?? "") :"
        toCurrency.text = "\(from ?? "") :"
        
        calculate()
    }
    
    @objc func doneButtonTappedForMyNumericTextField() {
        calculate()
        amount.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        calculate()
//        textField.resignFirstResponder()
//        return true
//    }
    @IBAction func from(_ sender: Any) {
        dropDown.anchorView = fromCurrencies
        dropDown.dataSource = currencies
        dropDown.show()
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.fromCurrencies.setTitle(item, for: .normal)
            self.fromCurrency.text = "\(item) :"
            self.calculate()
        }
        dropDown.reloadAllComponents()
    }
    
    @IBAction func to(_ sender: Any) {
        dropDown.anchorView = toCurrencies
        dropDown.dataSource = currencies
        dropDown.show()
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.toCurrencies.setTitle(item, for: .normal)
            self.toCurrency.text = "\(item) :"
            self.calculate()
        }
        dropDown.reloadAllComponents()
    }
    
    func calculate(){
        if var base = fromCurrency.text{
            if base.contains(" :"){
                base = base.replacingOccurrences(of: " :", with: "", options: NSString.CompareOptions.literal, range: nil)
            }
            let baseUrl = "https://api.exchangeratesapi.io/latest?base=\(base)"
            Alamofire.request(baseUrl, method: .get).responseJSON{ response in
                if response.result.isSuccess
                {
                    let sourceJSON : JSON = JSON(response.result.value!)
                    if var to = self.toCurrency.text{
                        if to.contains(" :"){
                            to = to.replacingOccurrences(of: " :", with: "", options: NSString.CompareOptions.literal, range: nil)
                        }
                        let rates = sourceJSON["rates"][to]
                        let rateDouble = rates.double
                        self.rate.text = "\(rateDouble ?? 0)"
                        var amountText = self.amount.text
                        self.fromValue.text = amountText
                        if amountText?.filter({$0 == ","}).count ?? 0 > 1{
                            let alert = UIAlertController(title: "Title", message: "Please enter proper number!", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                            self.fromValue.text = ""
                            self.toValue.text = ""
                            self.present(alert, animated: true, completion: nil)
                        }else{
                            amountText = amountText?.replacingOccurrences(of: ",", with: ".")
                            var calc : Double?
                            if let amountValue = amountText, let am = Double(amountValue) {
                                calc = Double(rateDouble!) * am
                            }
                            self.toValue.text = "\(calc ?? 0)"
                            if self.toValue.text == "0.0"{
                                self.toValue.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func convert(_ sender: Any) {
        calculate()
    }
    
}

extension UITextField {
    func addDoneCancelToolbar(onDone: (target: Any, action: Selector)? = nil, onCancel: (target: Any, action: Selector)? = nil) {
        let onCancel = onCancel ?? (target: self, action: #selector(cancelButtonTapped))
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))
        
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: onCancel.target, action: onCancel.action),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
    @objc func cancelButtonTapped() { self.resignFirstResponder() }
}
