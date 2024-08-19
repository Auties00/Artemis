//
//  CountryCodesResponse.swift
//   Artemis
//
//  Created by Alessandro Autiero on 09/08/24.
//

import Foundation

struct CountriesResponse: Decodable {
    let countries: [String:Country]
    let callerCountryCode: String
    
    enum CodingKeys: CodingKey {
        case countries
        case callerCountryCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let countriesValues = try container.decode([Country].self, forKey: .countries)
        var countries: [String:Country] = [:]
        for country in countriesValues {
            countries[country.iso3166Alpha2] = country
            countries[country.iso3166Alpha3] = country
        }
        self.countries = countries
        self.callerCountryCode = try container.decode(String.self, forKey: .callerCountryCode)
    }
}

struct Country: Decodable {
    let iso3166Alpha2: String
    let iso3166Alpha3: String
    let name: String
    let addressRequiredFields: [String:AddressRequiredField]
    
    enum CodingKeys: String, CodingKey {
        case iso3166Alpha2 = "iso3166alpha2"
        case iso3166Alpha3 = "iso3166alpha3"
        case name
        case addressRequiredFields
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.iso3166Alpha2 = try container.decode(String.self, forKey: .iso3166Alpha2)
        self.iso3166Alpha3 = try container.decode(String.self, forKey: .iso3166Alpha3)
        let addressRequiredFieldsValues = try container.decode([AddressRequiredField].self, forKey: .addressRequiredFields)
        var addressRequiredFields: [String:AddressRequiredField] = [:]
        for addressRequiredField in addressRequiredFieldsValues {
            addressRequiredFields[addressRequiredField.fieldName] = addressRequiredField
        }
        self.addressRequiredFields = addressRequiredFields
    }
}

struct AddressRequiredField: Decodable {
    let fieldName: String
    let required: Bool
    let acceptableValues: [String:String]
    
    enum CodingKeys: CodingKey {
        case fieldName
        case required
        case acceptableValues
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fieldName = try container.decode(String.self, forKey: .fieldName)
        self.required = try container.decode(Bool.self, forKey: .required)
        let acceptableValuesData = try container.decodeIfPresent([AcceptableValue].self, forKey: .acceptableValues) ?? []
        var acceptableValues: [String:String] = [:]
        for acceptableValue in acceptableValuesData {
            acceptableValues[acceptableValue.value] = acceptableValue.displayName
        }
        self.acceptableValues = acceptableValues
    }
}

struct AcceptableValue: Decodable {
    let value: String
    let displayName: String
}
