//
//  AbstractValidatedCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// Callback that accepts user input often need to validate that input either on the client side, the server side
/// or both.  Such callback should extend this base class.
@objc(FRAbstractValidatedCallback)
public class AbstractValidatedCallback: SingleValueCallback {
    
    //  MARK: - Property
    
    /// Policies that will validate user input
    @objc public var policies: [String]?
    /// An array of FailedPolicy for user input validation
    @objc public var failedPolicies: [FailedPolicy]?
    
    
    //  MARK: - Init 
    
    /// Designated initialization method for AbstractValidatedCallback
    ///
    /// - Parameter json: JSON object of AbstractValidatedCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        try super.init(json: json)
        
        guard let outputs = json["output"] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let name = output["name"] as? String, name == "prompt", let prompt = output["value"] as? String {
                self.prompt = prompt
            } else if let name = output["name"] as? String, name == "policies", let policies = output["value"] as? [String] {
                self.policies = policies
            }
        }
        
        for output in outputs {
            if let name = output["name"] as? String, name == "failedPolicies", let failedPolicies = output["value"] as? [String], failedPolicies.count > 0 {
                self.failedPolicies = []
                for policy in failedPolicies {
                    if let strData = policy.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: strData, options: []) as? [String: Any], let propertyName = self.prompt {
                                self.failedPolicies?.append(try FailedPolicy(propertyName, json))
                            }
                            else {
                                throw AuthError.invalidCallbackResponse("Failed to parse FailedPolicies from callback response: \(json)")
                            }
                        } catch {
                            throw AuthError.invalidCallbackResponse("Failed to parse FailedPolicies from callback response: \(json)")
                        }
                    }
                }
                FRLog.w("\(self.type) is returned with FailedPolicies: \(failedPolicies)")
            }
        }
    }
}

/// FailedPolicy that describes reason, and additional information for user input validation failure
@objc(FRFailedPolicy)
public class FailedPolicy: NSObject {
    
    // MARK: Property
    
    /// Property name (prompt in Callback) of FailedPolicy
    private var propertyName: String
    /// Failed policy parameter that explains specific requirement, and reason for failure
    @objc public var params: [String: Any]?
    /// Policy requirement that states specific policy that failed
    @objc public var policyRequirement: String
    
    
    // MARK: Init
    
    /// Constructs FailedPolicy object with property name, and raw JSON response from OpenAM
    ///
    /// - Parameters:
    ///   - propertyName: Property name of failed policy; 'prompt' property in Callback object
    ///   - json: Raw JSON response from OpenAM for a specific failed policy
    /// - Throws: AuthError.invalidCallbackResponse when 'policyRequirement' attribute is missing on raw JSON response
    init(_ propertyName: String, _ json: [String: Any]) throws {
        self.propertyName = propertyName
        self.params = json["params"] as? [String: Any]
        if let policyRequirement = json["policyRequirement"] as? String {
            self.policyRequirement = policyRequirement
        }
        else {
            throw AuthError.invalidCallbackResponse("Failed to parse FailedPolicies from callback response: \(json)")
        }
    }
    
    
    // MARK: Public
    
    /// Generates, and returns human readable failed reason
    ///
    /// - Returns: String value of human readable failed policy
    @objc public func failedDescription() -> String {
        
        if var failedPolicyDescription = failedPolicyMapping[policyRequirement] {
            
            failedPolicyDescription = failedPolicyDescription.replacingOccurrences(of: "%{propertyName}", with: propertyName)
            
            if let failedPolicyParams = params {
                for (key, value) in failedPolicyParams {
                    failedPolicyDescription = failedPolicyDescription.replacingOccurrences(of: "%{" + key + "}", with: String(describing: value))
                }
            }
            
            return failedPolicyDescription
        }
        
        return propertyName + ": Unknown policy requirement - " + policyRequirement
    }
    
    
    fileprivate let failedPolicyMapping: [String: String] = [
        FailedPolicy.required: "%{propertyName} is required",
        FailedPolicy.unique: "%{propertyName} must be unique",
        FailedPolicy.matchRegex: "",
        FailedPolicy.validType: "",
        FailedPolicy.validQueryFilter: "",
        FailedPolicy.validArrayItems: "",
        FailedPolicy.validDate: "Invalid date",
        FailedPolicy.validEmailAddressFormat: "Invalid Email format",
        FailedPolicy.validNameFormat: "Invalid name format",
        FailedPolicy.validPhoneFormat: "Invalid phone number",
        FailedPolicy.atLeastCapLetters: "%{propertyName} must contain at least %{numCaps} capital letter(s)",
        FailedPolicy.atLeastNums: "%{propertyName} must contain at least %{numNums} numeric value(s)",
        FailedPolicy.validNum: "Invalid number",
        FailedPolicy.minNum: "",
        FailedPolicy.maxNum: "",
        FailedPolicy.minLength: "%{propertyName} must be at least %{minLength} character(s)",
        FailedPolicy.maxLength: "%{propertyName} must be at most %{maxLength} character(s)",
        FailedPolicy.cannotContainOthers: "%{propertyName} must not contain: %{disallowedFields}",
        FailedPolicy.cannotContainChars: "%{propertyName} must not contain following characters: %{forbiddenChars}",
        FailedPolicy.cannotContainDuplicates: "%{propertyName} must not contain duplicates: %{duplicateValue}}",
    ]
    
    private static let required = "REQUIRED"
    private static let unique = "UNIQUE"
    private static let matchRegex = "MATCH_REGEXP"
    private static let validType = "VALID_TYPE"
    private static let validQueryFilter = "VALID_QUERY_FILTER"
    private static let validArrayItems = "VALID_ARRAY_ITEMS"
    private static let validDate = "VALID_DATE"
    private static let validEmailAddressFormat = "VALID_EMAIL_ADDRESS_FORMAT"
    private static let validNameFormat = "VALID_NAME_FORMAT"
    private static let validPhoneFormat = "VALID_PHONE_FORMAT"
    private static let atLeastCapLetters = "AT_LEAST_X_CAPITAL_LETTERS"
    private static let atLeastNums = "AT_LEAST_X_NUMBERS"
    private static let validNum = "VALID_NUMBER"
    private static let minNum = "MINIMUM_NUMBER_VALUE"
    private static let maxNum = "MAXIMUM_NUMBER_VALUE"
    private static let minLength = "MIN_LENGTH"
    private static let maxLength = "MAX_LENGTH"
    private static let cannotContainOthers = "CANNOT_CONTAIN_OTHERS"
    private static let cannotContainChars = "CANNOT_CONTAIN_CHARACTERS"
    private static let cannotContainDuplicates = "CANNOT_CONTAIN_DUPLICATES"
}
