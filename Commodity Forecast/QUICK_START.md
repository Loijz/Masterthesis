# Quick Start Guide

## Understanding How URLs Work

### ❌ What DOESN'T Work

```python
# This will ONLY scrape the homepage, not find articles
scraper.scrape_url("https://www.mining.com")
```

### ✓ What DOES Work

You need **specific article URLs** or use the **URL finder** to discover them.

---

## Three Ways to Use This Tool

### 1️⃣ I Have Specific Article URLs

**When to use:** You already found specific articles about iron ore forecasts

```python
from iron_ore_scraper import IronOreForecastScraper

scraper = IronOreForecastScraper()

# Use direct article URLs
urls = [
    "https://www.mining.com/iron-ore-prices-forecast-2024/",
    "https://www.reuters.com/article/iron-ore-outlook-idUSL1N3KL0AB",
]

scraper.scrape_urls(urls)
scraper.export_to_csv('forecasts.csv')
```

**How to find article URLs:**
1. Go to mining news websites
2. Search for "iron ore forecast" or "iron ore outlook"
3. Copy the URL of each relevant article
4. Add them to your script

---

### 2️⃣ Auto-Discover Articles (Crawler)

**When to use:** You have a website but don't know which articles to scrape

```python
from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper

# Step 1: Discover articles
finder = IronOreArticleFinder()
finder.search_website(
    "https://www.mining.com/",
    max_pages=30,    # How many pages to check
    max_depth=2      # How deep to crawl (2 = homepage + linked pages)
)

# Step 2: Scrape discovered articles
scraper = IronOreForecastScraper()
scraper.scrape_urls(finder.get_urls_list())
scraper.export_to_csv('forecasts.csv')
```

**How it works:**
- Starts at your URL (e.g., homepage)
- Follows links to find articles
- Filters for iron ore + forecast content
- Returns list of relevant article URLs

---

### 3️⃣ Search Specific Sections

**When to use:** Target specific news/commodity sections of websites

```python
from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper

finder = IronOreArticleFinder()

# Search specific sections
finder.search_news_section(
    "https://www.mining.com/category/commodities/",
    max_articles=50
)

# Scrape found articles
scraper = IronOreForecastScraper()
scraper.scrape_urls(finder.get_urls_list())
scraper.export_to_csv('forecasts.csv')
```

**Best sections to search:**
- `/news/`
- `/commodities/`
- `/metals/`
- `/market-insights/`
- `/category/mining/`

---

## Complete Workflow Example

```python
# complete_workflow.py - Edit and run this
from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper

# 1. Find articles
finder = IronOreArticleFinder()

# Option A: Crawl from starting point
finder.search_website("https://www.mining.com/", max_pages=30, max_depth=2)

# Option B: Search specific sections (can do multiple)
# finder.search_news_section("https://www.reuters.com/markets/commodities/", max_articles=50)
# finder.search_news_section("https://www.mining.com/category/metals/", max_articles=50)

# 2. Save discovered URLs (optional)
finder.save_results('found_urls.txt')

# 3. Scrape the articles
scraper = IronOreForecastScraper()
scraper.scrape_urls(finder.get_urls_list())

# 4. View and export results
scraper.print_summary()
scraper.export_to_csv('iron_ore_forecasts.csv')
scraper.export_to_json('iron_ore_forecasts.json')
```

---

## Real-World Example Websites

### Mining.com
```python
# Homepage crawl
finder.search_website("https://www.mining.com/", max_pages=30, max_depth=2)

# Or target their commodities section
finder.search_news_section("https://www.mining.com/category/commodities/", max_articles=50)
```

### Reuters
```python
# Target commodities section
finder.search_news_section("https://www.reuters.com/markets/commodities/", max_articles=50)
```

### S&P Global
```python
# Target metals news section
finder.search_news_section(
    "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/",
    max_articles=50
)
```

---

## What Gets Extracted

For each article, the scraper extracts:

| Field | Example |
|-------|---------|
| **forecast_date** | 2024-03-15 (when forecast was published) |
| **outlook_date** | Q2 2024, 2025, March 2024 |
| **price_usd** | 120.50 |
| **price_range** | 100-130 |
| **context** | Surrounding text for verification |

Output formats:
- **CSV**: `iron_ore_forecasts.csv` (for Excel)
- **JSON**: `iron_ore_forecasts.json` (for code)

---

## Tips for Best Results

### Finding Good URLs
1. Use Google: `"iron ore forecast" site:mining.com`
2. Browse news sections manually first
3. Look for articles from 2013-2025
4. Check for "62%", "CFR China", "Platts" keywords

### Crawler Settings
- **Small sites**: `max_pages=20, max_depth=2`
- **Large sites**: `max_pages=50, max_depth=1` (shallower but broader)
- **News sections**: Use `search_news_section()` instead

### Verification
- Always check the `context` field in output
- Verify prices are reasonable ($20-$300/tonne)
- Cross-reference multiple sources

---

## Troubleshooting

### "No articles found"
- Try a different starting URL (use /news/ or /commodities/ sections)
- Increase `max_pages` parameter
- Use `search_news_section()` for targeted search
- Check if site blocks crawlers

### "No forecasts extracted"
- Article might not contain price/date information
- Check if content is behind paywall
- Review `context` field to see what was extracted
- Try different articles from same source

### "Wrong data extracted"
- Review the `context` field to verify
- Adjust patterns in `iron_ore_scraper.py` if needed
- Some articles may need manual verification

---

## Next Steps

1. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Choose your approach**
   - Have URLs? → Use Method 1
   - Need to find URLs? → Use Method 2 or 3

3. **Run the scraper**
   ```bash
   python complete_workflow.py
   ```

4. **Check results**
   - Open `iron_ore_forecasts.csv` in Excel
   - Review the `context` field for accuracy

5. **Iterate**
   - Add more URLs or sections
   - Adjust crawler parameters
   - Filter results by date range
