//
//  instructions.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/23/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import FoundationModels

let instructions = Instructions {
    "You are a helpful portfolio assistant, returning information in a chat-friendly way that explains reasoning."
    
    "You must call the get_holdings tool for all holdings questions."
    
    "For casual conversation, greetings, or general questions not related to portfolio data, respond naturally without calling any tools."
    
    """
    For holdings queries, use `get_holdings` which returns JSON containing:
        - 'holdings': array of matching holdings with complete data \
          (symbol, marketvalueinbccy, marketplinsccy, assetclass, countryregion, accounttype, etc.)
        - 'count': number of filtered results
        - 'total_holdings': total portfolio holdings count
    """
    
    """
    Here is an example, but do not copy it exactly:

    Example query:
    "Show my US equities holdings."

    Example response:
    {
        "holdings": [
            {
                "symbol": "AAPL",
                "marketvalueinbccy": 32000.0,
                "marketplinsccy": 4000.0,
                "assetclass": "Equity",
                "countryregion": "United States",
                "accounttype": "Brokerage"
            },
            {
                "symbol": "TSLA",
                "marketvalueinbccy": 15000.0,
                "marketplinsccy": 3000.0,
                "assetclass": "Equity",
                "countryregion": "United States",
                "accounttype": "Brokerage"
            }
        ],
        "count": 2,
        "total_holdings": 4
    }
    """
}


extension HoldingsResponse {
    static let examplePortfolio = HoldingsResponse(
        holdings: [
            Holding(
                symbol: "AAPL",
                cusip: "037833100",
                fxrate: 1.0,
                marketvalueinbccy: 32000.0,
                totalmarketvalue: 32000.0,
                assetclass: "Equity",
                uuid: "holding-001",
                costpricesccy: 150.0,
                accrualsymbol: "",
                totalcostinbccy: 28000.0,
                maturitydate: nil,
                assettemplatetype: "Stock",
                marketyield: nil,
                accruedcashvaluesccy: 0.0,
                marketpricesccy: 160.0,
                marketplinsccy: 4000.0,
                forexpl: 0.0,
                accounttype: "Brokerage",
                countryregion: "United States",
                marketplinbccy: 4000.0,
                marketplpercentinsccy: 14.29,
                accrualtype: "None",
                totalmarketvaluesccy: 32000.0,
                totalmarketvalueccy: 32000.0,
                ytm: nil,
                securitytype: "Stock",
                accrualsccy: 0.0,
                fxmarket: 32000.0,
                sccy: "USD"
            ),
            Holding(
                symbol: "TSLA",
                cusip: "88160R101",
                fxrate: 1.0,
                marketvalueinbccy: 18000.0,
                totalmarketvalue: 18000.0,
                assetclass: "Equity",
                uuid: "holding-002",
                costpricesccy: 240.0,
                accrualsymbol: "",
                totalcostinbccy: 20000.0,
                maturitydate: nil,
                assettemplatetype: "Stock",
                marketyield: nil,
                accruedcashvaluesccy: 0.0,
                marketpricesccy: 216.0,
                marketplinsccy: -2000.0,
                forexpl: 0.0,
                accounttype: "Brokerage",
                countryregion: "United States",
                marketplinbccy: -2000.0,
                marketplpercentinsccy: -10.0,
                accrualtype: "None",
                totalmarketvaluesccy: 18000.0,
                totalmarketvalueccy: 18000.0,
                ytm: nil,
                securitytype: "Stock",
                accrualsccy: 0.0,
                fxmarket: 18000.0,
                sccy: "USD"
            )
        ],
        count: 2,
        total_holdings: 4
    )
}
