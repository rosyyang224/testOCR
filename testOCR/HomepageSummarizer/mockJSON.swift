import Foundation

let mockJSON = """
{
  "portfolio_value": [
    { "clientID": "123456", "marketChange": 1200.50, "marketValue": 135000.00, "valueDate": "2024-08-01" },
    { "clientID": "123456", "marketChange": 800.00, "marketValue": 136200.00, "valueDate": "2024-09-01" },
    { "clientID": "123456", "marketChange": -400.00, "marketValue": 135800.00, "valueDate": "2024-10-01" },
    { "clientID": "123456", "marketChange": 1500.25, "marketValue": 137300.25, "valueDate": "2024-11-01" },
    { "clientID": "123456", "marketChange": 950.00, "marketValue": 138250.25, "valueDate": "2024-12-01" },
    { "clientID": "123456", "marketChange": -200.00, "marketValue": 138050.25, "valueDate": "2025-01-01" },
    { "clientID": "123456", "marketChange": 1700.00, "marketValue": 139750.25, "valueDate": "2025-02-01" },
    { "clientID": "123456", "marketChange": 1200.00, "marketValue": 140950.25, "valueDate": "2025-03-01" },
    { "clientID": "123456", "marketChange": -600.00, "marketValue": 140350.25, "valueDate": "2025-04-01" },
    { "clientID": "123456", "marketChange": 1800.00, "marketValue": 142150.25, "valueDate": "2025-05-01" },
    { "clientID": "123456", "marketChange": 900.00, "marketValue": 143050.25, "valueDate": "2025-06-01" },
    { "clientID": "123456", "marketChange": 1550.30, "marketValue": 144600.55, "valueDate": "2025-07-01" }
  ],
  "top_movers": [
    {
      "cusip": "037833100",
      "description": "Apple Inc.",
      "marketPLPercentInBccy": 3.5,
      "marketPLInBccy": 5400.00,
      "accountType": "Brokerage",
      "totalMarketValue": 32000.00,
      "shares": 100,
      "assetClass": "Equity",
      "uuid": "asset-1"
    },
    {
      "cusip": "02079K305",
      "description": "Alphabet Inc.",
      "marketPLPercentInBccy": 2.8,
      "marketPLInBccy": 3100.00,
      "accountType": "Brokerage",
      "totalMarketValue": 25000.00,
      "shares": 80,
      "assetClass": "Equity",
      "uuid": "asset-3"
    }
  ],
  "top_losers": [
    {
      "cusip": "88160R101",
      "description": "Tesla Inc.",
      "marketPLPercentInBccy": -4.1,
      "marketPLInBccy": -2800.00,
      "accountType": "Brokerage",
      "totalMarketValue": 18000.00,
      "shares": 50,
      "assetClass": "Equity",
      "uuid": "asset-2"
    },
    {
      "cusip": "BABA880011",
      "description": "Alibaba Group",
      "marketPLPercentInBccy": -3.7,
      "marketPLInBccy": -2200.00,
      "accountType": "Brokerage",
      "totalMarketValue": 14000.00,
      "shares": 70,
      "assetClass": "Equity",
      "uuid": "asset-4"
    }
  ],
  "allocation_by_asset_class": [
    { "assetClass": "Equity", "percentage": 62.3, "marketValue": 94500.00 },
    { "assetClass": "Fixed Income", "percentage": 24.1, "marketValue": 36500.00 },
    { "assetClass": "Cash", "percentage": 13.6, "marketValue": 20600.00 }
  ]
}
"""
