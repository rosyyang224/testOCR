//
//  FieldTagsConfig.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/15/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import Foundation

/// Configuration file containing semantic tags for portfolio holding fields
struct FieldTagsConfig {
    
    // MARK: - Field Semantic Tags
    
    static let fieldSemanticTags: [String: [String]] = [
        // Symbol and identification
        "symbol": ["ticker", "stock symbol", "code", "instrument", "security code"],
        "cusip": ["identifier", "cusip", "security id", "unique identifier"],
        "uuid": ["id", "unique id", "identifier", "uuid"],
        
        // Market values and pricing
        "marketvalueinbccy": ["market value", "current value", "market worth", "position value"],
        "totalmarketvalue": ["total value", "market cap", "position size", "investment value", "worth"],
        "totalmarketvaluesccy": ["market value", "current value", "position value", "worth"],
        "totalmarketvalueccy": ["market value", "current value", "position value", "worth"],
        "marketpricesccy": ["market price", "current price", "stock price", "share price", "price"],
        "costpricesccy": ["cost price", "purchase price", "buy price", "cost basis"],
        
        // Performance and P&L
        "marketplinsccy": ["profit loss", "pnl", "gain loss", "performance amount", "profit", "loss"],
        "marketplinbccy": ["profit loss", "pnl", "gain loss", "performance amount", "profit", "loss"],
        "marketplpercentinsccy": ["performance", "return", "gain", "loss", "percentage return", "profit percent", "performance percentage"],
        "forexpl": ["forex gain", "currency gain", "fx profit", "exchange rate profit"],
        
        // Cost and investment basis
        "totalcostinbccy": ["cost basis", "total cost", "investment cost", "purchase amount"],
        "accruedcashvaluesccy": ["accrued cash", "dividend accrual", "interest accrual", "accumulated cash"],
        "accrualsccy": ["accrual", "accumulated interest", "accrued amount"],
        
        // Asset classification
        "assetclass": ["asset type", "asset class", "category", "investment type", "security type"],
        "assettemplatetype": ["template", "asset template", "type template", "security template"],
        "securitytype": ["security type", "instrument type", "investment type"],
        "accounttype": ["account", "account type", "brokerage type"],
        
        // Geographic and regional
        "countryregion": ["country", "region", "geography", "location", "domicile", "market region"],
        
        // Currency and FX
        "fxrate": ["exchange rate", "fx rate", "currency rate", "conversion rate"],
        "fxmarket": ["fx market", "foreign exchange", "currency market"],
        "sccy": ["currency", "base currency", "settlement currency"],
        
        // Yield and income
        "marketyield": ["yield", "income yield", "dividend yield", "interest rate"],
        "ytm": ["yield to maturity", "ytm", "bond yield", "maturity yield"],
        
        // Dates and timing
        "maturitydate": ["maturity", "expiry", "expiration date", "end date", "maturity date"],
        
        // Accrual and accounting
        "accrualsymbol": ["accrual symbol", "accrual code", "interest symbol"],
        "accrualtype": ["accrual type", "interest type", "dividend type", "accrual method"]
    ]
    
    // MARK: - Query Intent Tags
    
    static let queryIntentTags: [String: [String]] = [
        "performance": ["performance", "return", "gain", "loss", "profit", "pnl", "growth", "decline"],
        "value": ["value", "worth", "amount", "size", "position", "investment"],
        "pricing": ["price", "cost", "rate", "valuation", "pricing"],
        "geography": ["country", "region", "location", "geographic", "international", "domestic"],
        "asset_type": ["type", "class", "category", "asset", "security"],
        "currency": ["currency", "fx", "exchange", "foreign exchange"],
        "yield": ["yield", "income", "dividend", "interest", "payout"],
        "timing": ["date", "time", "maturity", "expiry", "period"],
        "identification": ["symbol", "id", "code", "identifier", "ticker"]
    ]
    
    // MARK: - Value Type Tags for Filtering
    
    static let valueTypeTags: [String: [String]] = [
        // Asset classes
        "equity": ["stock", "equity", "share", "common stock", "ordinary shares"],
        "bond": ["bond", "fixed income", "debt", "treasury", "corporate bond"],
        "etf": ["etf", "fund", "index fund", "exchange traded fund"],
        "cash": ["cash", "money market", "cash equivalent"],
        
        // Geographic regions
        "united_states": ["us", "usa", "america", "american", "united states", "domestic"],
        "international": ["international", "foreign", "overseas", "global", "non-us"],
        "europe": ["europe", "european", "eu", "eurozone"],
        "asia": ["asia", "asian", "china", "japan", "korea"],
        
        // Account types
        "brokerage": ["brokerage", "trading account", "investment account"],
        "retirement": ["ira", "401k", "retirement", "pension"],
        "taxable": ["taxable", "regular account", "non-retirement"],
        
        // Security types
        "stock": ["stock", "equity", "common stock", "share"],
        "bond": ["bond", "note", "treasury", "corporate bond"],
        "option": ["option", "call", "put", "derivative"],
        "mutual_fund": ["mutual fund", "fund", "managed fund"]
    ]
    
    // MARK: - Operator Tags for Query Processing
    
    static let operatorTags: [String: [String]] = [
        "greater": ["above", "over", "more than", "higher", "greater", "exceeds", "top", "largest", "biggest"],
        "less": ["below", "under", "less than", "lower", "smaller", "bottom", "smallest"],
        "equals": ["equals", "is", "exactly", "same as", "equal to"],
        "contains": ["includes", "has", "contains", "with", "featuring"],
        "positive": ["positive", "gaining", "up", "winning", "profitable", "green", "increasing"],
        "negative": ["negative", "losing", "down", "declining", "unprofitable", "decreasing"],
        "between": ["between", "range", "from to", "within"],
        "not": ["not", "except", "excluding", "without", "other than"]
    ]
}