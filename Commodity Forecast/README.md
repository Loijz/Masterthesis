# Iron Ore Price Forecast Scraper

A web scraping tool designed to collect 62% iron ore price forecasts from financial and commodity trading websites.

## Features

- **Web Scraping**: Fetches content from financial news websites and reports
- **Intelligent Extraction**: Uses pattern matching to extract:
  - Forecast publication date (when the forecast was made)
  - Outlook date (the date/period the forecast applies to)
  - Price in USD per tonne (single prices or ranges)
  - Context around the forecast for verification
- **Multiple Export Formats**: Saves data to CSV and JSON
- **Flexible**: Works with news articles, not just structured data files

## Installation

1. Install Python 3.8 or higher
2. Install required packages:

```bash
pip install -r requirements.txt
```

## Usage

### IMPORTANT: Understanding URLs

**❌ The scraper does NOT crawl entire websites automatically**

If you provide `https://www.mining.com`, it will **only** scrape that homepage, not all articles.

**✓ You have two options:**

1. **Provide specific article URLs** - Direct links to forecast articles
2. **Use the URL finder** - Automatically discovers article URLs for you

### Option 1: Quick Start with Specific URLs

If you already have article URLs:

1. Add them to `config_urls.py` or directly in code
2. Run the scraper:

```bash
python iron_ore_scraper.py
```

### Option 2: Discover Articles Automatically

Use the complete workflow to find and scrape articles:

```bash
python complete_workflow.py
```

Choose from:
- **Auto-discover**: Crawl a website to find articles automatically
- **Search sections**: Target specific news/commodity sections
- **Manual URLs**: Provide URLs you already have

### Programmatic Usage

**Method 1: Scrape specific article URLs you already have**

```python
from iron_ore_scraper import IronOreForecastScraper

scraper = IronOreForecastScraper()

# Scrape specific article URLs
urls = [
    "https://www.mining.com/iron-ore-forecast-article-123/",
    "https://www.reuters.com/markets/commodities/iron-ore-outlook-456/",
]

scraper.scrape_urls(urls)
scraper.export_to_csv('my_forecasts.csv')
```

**Method 2: Automatically discover articles from a website**

```python
from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper

# Step 1: Find articles
finder = IronOreArticleFinder()
finder.search_website("https://www.mining.com/", max_pages=30, max_depth=2)

# Step 2: Scrape found articles
scraper = IronOreForecastScraper()
scraper.scrape_urls(finder.get_urls_list())
scraper.export_to_csv('discovered_forecasts.csv')
```

**Method 3: Search specific news sections**

```python
from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper

finder = IronOreArticleFinder()

# Search news/commodities sections
finder.search_news_section("https://www.mining.com/category/commodities/", max_articles=50)
finder.search_news_section("https://www.reuters.com/markets/commodities/", max_articles=50)

# Scrape found articles
scraper = IronOreForecastScraper()
scraper.scrape_urls(finder.get_urls_list())
scraper.export_to_csv('section_forecasts.csv')
```

## Data Structure

Each forecast entry contains:

| Field | Description |
|-------|-------------|
| `source_name` | Website/source name |
| `source_url` | URL of the article |
| `forecast_date` | When the forecast was published |
| `outlook_date` | Date/period the forecast applies to |
| `price_usd` | Single price in USD per tonne |
| `price_range_min` | Minimum price if a range is given |
| `price_range_max` | Maximum price if a range is given |
| `context` | Surrounding text for context |
| `scraped_date` | When the data was scraped |

## Finding Target URLs

The scraper works best with:

1. **News Articles**: Reuters, Bloomberg, Financial Times commodity news
2. **Industry Reports**: Mining.com, Fastmarkets, S&P Global Platts
3. **Market Analysis**: Wood Mackenzie, Fitch Solutions reports
4. **Quarterly Outlooks**: Major mining companies' investor presentations
5. **Research Reports**: Investment bank commodity reports

### Recommended Sources

Check `config_urls.py` for a list of recommended sources, including:
- Reuters Commodities
- S&P Global Commodity Insights
- Mining.com
- Fastmarkets
- World Bank Commodity Markets

### Search Strategy

Use search engines with queries like:
- "iron ore price forecast [year]"
- "62% iron ore CFR China outlook"
- "Platts iron ore price predictions"
- "iron ore quarterly forecast"

## Pattern Recognition

The scraper recognizes:

### Price Patterns
- "$120 per tonne"
- "USD 125/ton"
- "prices of $130"
- "trading at $115"
- "$100 to $120" (ranges)
- "between $110 and $130"

### Date Patterns
- "in 2024"
- "Q1 2025"
- "by March 2024"
- "H2 2023" (half-year)
- "first quarter 2024"

### Iron Ore Keywords
- 62%, 62 percent
- Iron ore, iron-ore
- CFR China, CFR Qingdao
- Platts iron ore
- FE62

## Output Files

### CSV Output (`iron_ore_forecasts.csv`)
Tabular format suitable for Excel analysis

### JSON Output (`iron_ore_forecasts.json`)
Structured format for programmatic processing

## Limitations & Notes

1. **Respectful Scraping**: The scraper includes delays between requests
2. **Terms of Service**: Always check website ToS before scraping
3. **Dynamic Content**: May not work with JavaScript-heavy sites
4. **Accuracy**: Manual verification recommended for critical data
5. **Rate Limiting**: Some sites may block excessive requests

## Tips for Best Results

1. **Specific Articles**: Target specific forecast articles rather than homepage URLs
2. **Recent Content**: Newer articles often have more structured content
3. **Multiple Sources**: Cross-reference data from multiple sources
4. **Manual Review**: Review the `context` field to verify extraction accuracy
5. **Date Filtering**: Filter results by `outlook_date` to focus on your target period (2013-2025)

## Troubleshooting

**No forecasts found?**
- Check if the URL contains iron ore price information
- Verify the article isn't behind a paywall
- Try different article URLs from the same source

**Wrong prices extracted?**
- Review the `context` field in the output
- Prices outside $20-$300/tonne are filtered as unrealistic
- Adjust price patterns if needed for your specific sources

**Missing dates?**
- Some articles may not clearly state forecast dates
- Check the `forecast_date` (publication date) as a fallback
- Quarter/year notation is preserved (e.g., "Q1 2024")

## Advanced Usage

### Custom Price Patterns

Add custom regex patterns to match specific price formats:

```python
scraper = IronOreForecastScraper()
scraper.price_patterns.append(r'your_custom_pattern_here')
```

### Filtering Results

```python
# Filter by year
forecasts_2024 = [f for f in scraper.forecasts if '2024' in str(f.outlook_date)]

# Filter by price range
high_forecasts = [f for f in scraper.forecasts if f.price_usd and f.price_usd > 100]
```

## Contributing

To improve pattern matching:
1. Add new regex patterns to the scraper class
2. Test with various article formats
3. Adjust the `iron_ore_keywords` list for better content filtering

## License

This tool is for educational and research purposes. Ensure compliance with website terms of service before scraping.
