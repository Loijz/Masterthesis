"""
Configuration file for iron ore forecast scraping targets
Add URLs to news articles, reports, and forecasts about 62% iron ore prices
"""

# Target URLs for scraping
# Add specific article URLs that contain iron ore price forecasts
TARGET_URLS = [
    # Reuters - Commodities and mining news
    # Example: "https://www.reuters.com/markets/commodities/...",

    # S&P Global Platts - Iron ore analysis
    # Example: "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/...",

    # Mining.com - Industry news
    # Example: "https://www.mining.com/...",

    # Metal Bulletin / Fastmarkets
    # Example: "https://www.fastmarkets.com/insights/...",

    # Bloomberg - Commodities
    # Example: "https://www.bloomberg.com/news/articles/...",

    # Financial Times - Mining and metals
    # Example: "https://www.ft.com/content/...",

    # Add your URLs here:
]

# Search queries that can be used to find relevant articles
SEARCH_QUERIES = [
    "iron ore price forecast 2024",
    "iron ore price outlook 2025",
    "62% iron ore CFR China forecast",
    "iron ore price predictions analysts",
    "iron ore quarterly outlook",
    "Platts iron ore forecast",
]

# Common sources for iron ore forecasts
RECOMMENDED_SOURCES = {
    "Reuters": "https://www.reuters.com/markets/commodities/",
    "S&P Global": "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/",
    "Mining.com": "https://www.mining.com/",
    "Fastmarkets": "https://www.fastmarkets.com/insights/",
    "Wood Mackenzie": "https://www.woodmac.com/",
    "World Bank Commodities": "https://www.worldbank.org/en/research/commodity-markets",
    "Trading Economics": "https://tradingeconomics.com/commodity/iron-ore",
    "Investing.com": "https://www.investing.com/commodities/iron-ore-62-cfr-futures",
}

# Date range filter
DATE_RANGE = {
    "start_year": 2013,
    "end_year": 2025
}
