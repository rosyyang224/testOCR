import Foundation

let mockJSON = """
{
  "performance": {
    "1_week": -0.8,
    "1_month": 2.4,
    "3_months": 5.6,
    "year_to_date": 11.3
  },
  "top_holdings": [
    { "symbol": "AAPL", "name": "Apple Inc.", "weight_percent": 22.4 },
    { "symbol": "TSLA", "name": "Tesla Inc.", "weight_percent": 14.2 },
    { "symbol": "MSFT", "name": "Microsoft Corp.", "weight_percent": 13.1 },
    { "symbol": "NVDA", "name": "NVIDIA Corp.", "weight_percent": 10.6 }
  ],
  "top_gainers": [
    { "symbol": "AMZN", "change_percent": 9.8 },
    { "symbol": "META", "change_percent": 7.3 },
    { "symbol": "GOOGL", "change_percent": 6.1 }
  ],
  "top_losers": [
    { "symbol": "BABA", "change_percent": -4.9 },
    { "symbol": "NIO", "change_percent": -3.7 },
    { "symbol": "INTC", "change_percent": -2.2 }
  ],
  "allocation_changes": {
    "added": [
      { "symbol": "AMD", "reason": "positive earnings report" },
      { "symbol": "NFLX", "reason": "revised guidance upward" }
    ],
    "removed": [
      { "symbol": "UBER", "reason": "weaker than expected growth" }
    ]
  }
}
"""
