//
//  RecipeParser.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import Foundation
// import SwiftSoup  // TODO: Add SwiftSoup package via Xcode: File > Add Package Dependencies > https://github.com/scinfu/SwiftSoup.git

class RecipeParser {
    enum ParserError: Error {
        case invalidURL
        case networkError(Error)
        case parsingError
        case noRecipeFound
    }
    
    // Primary method - try JSON-LD first, fallback to HTML
    func parseRecipe(from urlString: String) async throws -> ParsedRecipe {
        guard let url = URL(string: urlString) else {
            throw ParserError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ParserError.parsingError
        }
        
        // Try JSON-LD extraction first
        if let recipe = try? extractFromJSONLD(html: html) {
            return recipe
        }
        
        // Fallback to HTML parsing
        return try extractFromHTML(html: html, sourceURL: urlString)
    }
    
    private func extractFromJSONLD(html: String) throws -> ParsedRecipe {
        // Extract <script type="application/ld+json"> tags using regex
        let pattern = #"<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        
        for match in matches {
            guard match.numberOfRanges > 1,
                  let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            
            let jsonString = String(html[jsonRange])
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }
            
            // Check if this is a Recipe schema
            if let type = json["@type"] as? String,
               type == "Recipe" || type.contains("Recipe") {
                return try parseJSONLDRecipe(json)
            }
            
            // Handle array of objects
            if let graphs = json["@graph"] as? [[String: Any]] {
                for item in graphs {
                    if let type = item["@type"] as? String,
                       type == "Recipe" || type.contains("Recipe") {
                        return try parseJSONLDRecipe(item)
                    }
                }
            }
        }
        
        throw ParserError.noRecipeFound
    }
    
    private func parseJSONLDRecipe(_ json: [String: Any]) throws -> ParsedRecipe {
        guard let name = json["name"] as? String else {
            throw ParserError.parsingError
        }
        
        let description = json["description"] as? String
        let sourceURL = json["url"] as? String ?? ""
        
        // Parse times
        let prepTime = parseISO8601Duration(json["prepTime"] as? String ?? "") ?? 0
        let cookTime = parseISO8601Duration(json["cookTime"] as? String ?? "") ?? 0
        
        // Parse servings
        var servings = 4
        if let recipeYield = json["recipeYield"] as? String {
            servings = extractNumberFromString(recipeYield) ?? 4
        } else if let recipeYield = json["recipeYield"] as? Int {
            servings = recipeYield
        }
        
        // Parse ingredients
        var ingredients: [ParsedIngredient] = []
        if let recipeIngredients = json["recipeIngredient"] as? [String] {
            ingredients = recipeIngredients.map { parseIngredientString($0) }
        }
        
        // Parse instructions
        var steps: [ParsedStep] = []
        if let instructions = json["recipeInstructions"] as? [[String: Any]] {
            steps = instructions.enumerated().compactMap { (index, instruction) in
                guard let text = instruction["text"] as? String else { return nil }
                let duration = extractDurationFromText(text)
                return ParsedStep(orderIndex: index, instruction: text, durationSeconds: duration)
            }
        } else if let instructions = json["recipeInstructions"] as? [String] {
            steps = instructions.enumerated().map { (index, text) in
                let duration = extractDurationFromText(text)
                return ParsedStep(orderIndex: index, instruction: text, durationSeconds: duration)
            }
        } else if let instructions = json["recipeInstructions"] as? String {
            // Single string - split by newlines or periods
            let instructionLines = instructions.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            steps = instructionLines.enumerated().map { (index, text) in
                let duration = extractDurationFromText(text)
                return ParsedStep(orderIndex: index, instruction: text, durationSeconds: duration)
            }
        }
        
        return ParsedRecipe(
            name: name,
            description: description,
            sourceURL: sourceURL,
            prepTimeSeconds: prepTime,
            cookTimeSeconds: cookTime,
            servings: servings,
            ingredients: ingredients,
            steps: steps
        )
    }
    
    private func extractFromHTML(html: String, sourceURL: String) throws -> ParsedRecipe {
        // TODO: Implement HTML parsing with SwiftSoup once package is added
        // For now, return a basic recipe structure
        throw ParserError.parsingError
        
        /* Will implement with SwiftSoup:
        let doc = try SwiftSoup.parse(html)
        
        // Extract recipe name
        let name = try? doc.select("h1").first()?.text() ?? "Imported Recipe"
        
        // Extract ingredients
        let ingredients = try extractIngredients(from: doc)
        
        // Extract instructions
        let steps = try extractInstructions(from: doc)
        
        // Extract times (prep, cook, total)
        let times = extractTimes(from: doc)
        
        return ParsedRecipe(
            name: name ?? "Imported Recipe",
            description: nil,
            sourceURL: sourceURL,
            prepTimeSeconds: times.prep,
            cookTimeSeconds: times.cook,
            servings: extractServings(from: doc) ?? 4,
            ingredients: ingredients,
            steps: steps
        )
        */
    }
    
    private func extractDurationFromText(_ text: String) -> Int? {
        // Regex patterns for time extraction
        let patterns: [(String, Int)] = [
            (#"(\d+)\s*(?:hour|hr|hours|uur|uren)"#, 3600),
            (#"(\d+)\s*(?:minute|min|minutes|minuut|minuten)"#, 60),
            (#"(\d+)\s*(?:second|sec|seconds|seconde|seconden)"#, 1)
        ]
        
        var totalSeconds = 0
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if match.numberOfRanges > 1,
                       let numberRange = Range(match.range(at: 1), in: text),
                       let number = Int(text[numberRange]) {
                        totalSeconds += number * multiplier
                    }
                }
            }
        }
        
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    private func parseISO8601Duration(_ duration: String) -> Int? {
        // Parse ISO 8601 duration (e.g., "PT30M" = 30 minutes, "PT1H30M" = 90 minutes)
        guard duration.hasPrefix("PT") else { return nil }
        
        var totalSeconds = 0
        let durationString = String(duration.dropFirst(2)) // Remove "PT"
        
        // Extract hours
        if let hRange = durationString.range(of: #"(\d+)H"#, options: .regularExpression),
           let hours = Int(durationString[hRange].dropLast()) {
            totalSeconds += hours * 3600
        }
        
        // Extract minutes
        if let mRange = durationString.range(of: #"(\d+)M"#, options: .regularExpression),
           let minutes = Int(durationString[mRange].dropLast()) {
            totalSeconds += minutes * 60
        }
        
        // Extract seconds
        if let sRange = durationString.range(of: #"(\d+)S"#, options: .regularExpression),
           let seconds = Int(durationString[sRange].dropLast()) {
            totalSeconds += seconds
        }
        
        return totalSeconds > 0 ? totalSeconds : nil
    }
    
    private func parseIngredientString(_ text: String) -> ParsedIngredient {
        // Simple parsing - extract quantity and unit if possible
        // Pattern: "2 cups flour" or "1/2 teaspoon salt"
        let pattern = #"^([\d\/\.\s]+)\s*([a-zA-Z]+)?\s*(.+)$"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges >= 4 {
            
            var quantity: Double = 0
            var unit = ""
            var name = text
            
            // Extract quantity
            if let quantityRange = Range(match.range(at: 1), in: text) {
                let quantityStr = String(text[quantityRange]).trimmingCharacters(in: .whitespaces)
                quantity = parseFraction(quantityStr)
            }
            
            // Extract unit
            if let unitRange = Range(match.range(at: 2), in: text) {
                unit = String(text[unitRange])
            }
            
            // Extract name
            if let nameRange = Range(match.range(at: 3), in: text) {
                name = String(text[nameRange])
            }
            
            return ParsedIngredient(name: name, quantity: quantity, unit: unit)
        }
        
        // Fallback: return whole string as name
        return ParsedIngredient(name: text, quantity: 0, unit: "")
    }
    
    private func parseFraction(_ str: String) -> Double {
        // Handle fractions like "1/2", "1 1/2", or simple decimals like "2.5"
        let components = str.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var total: Double = 0
        
        for component in components {
            if component.contains("/") {
                let parts = component.split(separator: "/")
                if parts.count == 2,
                   let numerator = Double(parts[0]),
                   let denominator = Double(parts[1]),
                   denominator != 0 {
                    total += numerator / denominator
                }
            } else if let number = Double(component) {
                total += number
            }
        }
        
        return total
    }
    
    private func extractNumberFromString(_ str: String) -> Int? {
        let numbers = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers)
    }
}

// MARK: - Parsed Data Structures
struct ParsedRecipe {
    let name: String
    let description: String?
    let sourceURL: String
    let prepTimeSeconds: Int
    let cookTimeSeconds: Int
    let servings: Int
    let ingredients: [ParsedIngredient]
    let steps: [ParsedStep]
}

struct ParsedIngredient {
    let name: String
    let quantity: Double
    let unit: String
}

struct ParsedStep {
    let orderIndex: Int
    let instruction: String
    let durationSeconds: Int?
}
