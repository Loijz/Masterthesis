"""
Iron Ore Price Forecast Scraper
Scrapes financial websites for 62% iron ore price forecasts between 2013-2025
"""

import requests
from bs4 import BeautifulSoup
import re
from datetime import datetime
from typing import List, Dict, Optional
import json
import csv
from dataclasses import dataclass, asdict
from urllib.parse import urljoin, urlparse
import time


@dataclass
class ForecastData:
    """Structure to hold forecast information"""
    source_url: str
    source_name: str
    forecast_date: Optional[str]  # When the forecast was made
    outlook_date: Optional[str]   # Date for which the forecast applies
    price_usd: Optional[float]    # Price in USD per tonne
    price_range_min: Optional[float]  # If range is given
    price_range_max: Optional[float]  # If range is given
    context: str  # Surrounding text for verification
    scraped_date: str  # When we scraped this

    def to_dict(self):
        return asdict(self)


class IronOreForecastScraper:
    """Main scraper class for iron ore price forecasts"""

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        self.forecasts: List[ForecastData] = []

        # Patterns for extracting iron ore prices and dates
        self.price_patterns = [
            r'\$(\d+(?:\.\d{1,2})?)\s*(?:per|/|a)\s*(?:tonne|ton|mt|t)',
            r'(?:USD|US\$)\s*(\d+(?:\.\d{1,2})?)',
            r'(\d+(?:\.\d{1,2})?)\s*(?:USD|dollars)\s*per\s*(?:tonne|ton)',
            r'price[s]?\s+(?:of|at|to|around|near)\s+\$?(\d+(?:\.\d{1,2})?)',
            r'(?:trade|trading|traded)\s+at\s+\$?(\d+(?:\.\d{1,2})?)',
        ]

        # Patterns for price ranges
        self.range_patterns = [
            r'\$(\d+(?:\.\d{1,2})?)\s*(?:to|-|and)\s*\$?(\d+(?:\.\d{1,2})?)',
            r'between\s+\$?(\d+(?:\.\d{1,2})?)\s+and\s+\$?(\d+(?:\.\d{1,2})?)',
            r'range\s+(?:of\s+)?\$?(\d+(?:\.\d{1,2})?)\s*-\s*\$?(\d+(?:\.\d{1,2})?)',
        ]

        # Date patterns
        self.date_patterns = [
            r'(?:in|by|for)\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})',
            r'(?:in|by|for)\s+(\d{4})',
            r'(Q[1-4])\s+(\d{4})',
            r'(?:first|second|third|fourth)\s+quarter\s+(?:of\s+)?(\d{4})',
            r'(H[1-2])\s+(\d{4})',  # Half-year notation
        ]

        # Keywords that indicate iron ore content
        self.iron_ore_keywords = [
            '62%', '62 %', '62 percent', 'fe 62', 'fe62',
            'iron ore', 'iron-ore', 'iron fines',
            'cfr china', 'cfr qingdao', 'platts'
        ]

    def fetch_page(self, url: str, timeout: int = 30) -> Optional[BeautifulSoup]:
        """Fetch and parse a webpage"""
        try:
            response = self.session.get(url, timeout=timeout)
            response.raise_for_status()
            return BeautifulSoup(response.content, 'html.parser')
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None

    def is_iron_ore_content(self, text: str) -> bool:
        """Check if text contains iron ore related content"""
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in self.iron_ore_keywords)

    def extract_prices(self, text: str) -> List[Dict]:
        """Extract price information from text"""
        prices = []

        # Check for price ranges
        for pattern in self.range_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    min_price = float(match.group(1))
                    max_price = float(match.group(2))
                    # Filter reasonable iron ore prices (typically $20-$200 per tonne)
                    if 20 <= min_price <= 300 and 20 <= max_price <= 300:
                        prices.append({
                            'type': 'range',
                            'min': min_price,
                            'max': max_price,
                            'position': match.start()
                        })
                except (ValueError, IndexError):
                    continue

        # Check for single prices
        for pattern in self.price_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    price = float(match.group(1))
                    # Filter reasonable iron ore prices
                    if 20 <= price <= 300:
                        prices.append({
                            'type': 'single',
                            'price': price,
                            'position': match.start()
                        })
                except (ValueError, IndexError):
                    continue

        return prices

    def extract_dates(self, text: str) -> List[Dict]:
        """Extract date information from text"""
        dates = []

        for pattern in self.date_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    date_info = {
                        'text': match.group(0),
                        'position': match.start()
                    }

                    # Parse different date formats
                    if 'Q' in match.group(0).upper():
                        quarter = match.group(1)
                        year = match.group(2)
                        date_info['parsed'] = f"{quarter} {year}"
                    elif 'H' in match.group(0).upper():
                        half = match.group(1)
                        year = match.group(2)
                        date_info['parsed'] = f"{half} {year}"
                    elif len(match.groups()) == 2 and match.group(1).isalpha():
                        month = match.group(1)
                        year = match.group(2)
                        date_info['parsed'] = f"{month} {year}"
                    else:
                        year = match.group(1) if len(match.groups()) == 1 else match.group(2)
                        date_info['parsed'] = year

                    dates.append(date_info)
                except (ValueError, IndexError):
                    continue

        return dates

    def extract_context(self, text: str, position: int, context_size: int = 200) -> str:
        """Extract surrounding context from text around a position"""
        start = max(0, position - context_size)
        end = min(len(text), position + context_size)
        return text[start:end].strip()

    def analyze_article(self, url: str, soup: BeautifulSoup, source_name: str) -> List[ForecastData]:
        """Analyze an article and extract forecast data"""
        forecasts = []

        # Extract main content (try common article containers)
        content_selectors = [
            'article', 'main', '.article-content', '.post-content',
            '.entry-content', '#content', '.story-body'
        ]

        content = None
        for selector in content_selectors:
            content = soup.select_one(selector)
            if content:
                break

        if not content:
            content = soup.find('body')

        if not content:
            return forecasts

        # Get all text
        text = content.get_text(separator=' ', strip=True)

        # Check if this is iron ore related content
        if not self.is_iron_ore_content(text):
            return forecasts

        # Extract article date (publication date)
        article_date = self.extract_article_date(soup)

        # Find all prices and dates
        prices = self.extract_prices(text)
        dates = self.extract_dates(text)

        # Match prices with nearby dates
        for price_info in prices:
            # Find closest date to this price
            closest_date = None
            min_distance = float('inf')

            for date_info in dates:
                distance = abs(price_info['position'] - date_info['position'])
                if distance < min_distance and distance < 500:  # Within 500 characters
                    min_distance = distance
                    closest_date = date_info

            # Create forecast entry
            forecast = ForecastData(
                source_url=url,
                source_name=source_name,
                forecast_date=article_date,
                outlook_date=closest_date['parsed'] if closest_date else None,
                price_usd=price_info.get('price'),
                price_range_min=price_info.get('min'),
                price_range_max=price_info.get('max'),
                context=self.extract_context(text, price_info['position']),
                scraped_date=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            )

            forecasts.append(forecast)

        return forecasts

    def extract_article_date(self, soup: BeautifulSoup) -> Optional[str]:
        """Extract publication date from article"""
        # Common date meta tags and selectors
        date_selectors = [
            ('meta', {'property': 'article:published_time'}),
            ('meta', {'name': 'publication_date'}),
            ('meta', {'name': 'date'}),
            ('time', {'class': 'published'}),
            ('time', {}),
            ('.publish-date', {}),
            ('.article-date', {}),
        ]

        for selector, attrs in date_selectors:
            element = soup.find(selector, attrs)
            if element:
                date_text = element.get('content') or element.get('datetime') or element.get_text()
                if date_text:
                    try:
                        # Try to parse and format the date
                        return self.parse_date_string(date_text)
                    except:
                        return date_text[:10] if len(date_text) >= 10 else date_text

        return None

    def parse_date_string(self, date_str: str) -> str:
        """Parse various date string formats"""
        # Try common date formats
        formats = ['%Y-%m-%d', '%Y/%m/%d', '%d-%m-%Y', '%d/%m/%Y', '%B %d, %Y', '%d %B %Y']

        for fmt in formats:
            try:
                dt = datetime.strptime(date_str[:10], fmt)
                return dt.strftime('%Y-%m-%d')
            except:
                continue

        return date_str

    def scrape_url(self, url: str, source_name: str = None):
        """Scrape a single URL"""
        if source_name is None:
            source_name = urlparse(url).netloc

        print(f"Scraping: {url}")
        soup = self.fetch_page(url)

        if soup:
            forecasts = self.analyze_article(url, soup, source_name)
            self.forecasts.extend(forecasts)
            print(f"  Found {len(forecasts)} forecast entries")
            time.sleep(1)  # Be polite to servers

    def scrape_urls(self, urls: List[str]):
        """Scrape multiple URLs"""
        for url in urls:
            self.scrape_url(url)

    def export_to_csv(self, filename: str = 'iron_ore_forecasts.csv'):
        """Export forecasts to CSV"""
        if not self.forecasts:
            print("No forecasts to export")
            return

        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=[
                'source_name', 'source_url', 'forecast_date', 'outlook_date',
                'price_usd', 'price_range_min', 'price_range_max',
                'context', 'scraped_date'
            ])
            writer.writeheader()
            for forecast in self.forecasts:
                writer.writerow(forecast.to_dict())

        print(f"Exported {len(self.forecasts)} forecasts to {filename}")

    def export_to_json(self, filename: str = 'iron_ore_forecasts.json'):
        """Export forecasts to JSON"""
        if not self.forecasts:
            print("No forecasts to export")
            return

        with open(filename, 'w', encoding='utf-8') as f:
            json.dump([f.to_dict() for f in self.forecasts], f, indent=2)

        print(f"Exported {len(self.forecasts)} forecasts to {filename}")

    def print_summary(self):
        """Print summary of scraped data"""
        print(f"\n{'='*60}")
        print(f"Scraping Summary")
        print(f"{'='*60}")
        print(f"Total forecasts found: {len(self.forecasts)}")

        if self.forecasts:
            sources = set(f.source_name for f in self.forecasts)
            print(f"Unique sources: {len(sources)}")

            with_dates = sum(1 for f in self.forecasts if f.outlook_date)
            print(f"Forecasts with outlook dates: {with_dates}")

            with_prices = sum(1 for f in self.forecasts if f.price_usd or f.price_range_min)
            print(f"Forecasts with prices: {with_prices}")


if __name__ == "__main__":
    # Example usage
    scraper = IronOreForecastScraper()

    # Add your target URLs here
    example_urls = [
        # Add URLs to articles about iron ore forecasts
        # Examples:
        # "https://www.reuters.com/markets/commodities/iron-ore-prices-forecast-2024",
        # "https://www.mining.com/iron-ore-price-outlook",
        # "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/iron-ore",
    ]

    if example_urls and example_urls[0]:
        scraper.scrape_urls(example_urls)
        scraper.print_summary()
        scraper.export_to_csv()
        scraper.export_to_json()
    else:
        print("Please add URLs to scrape in the example_urls list")
        print("\nYou can use this scraper programmatically:")
        print("  from iron_ore_scraper import IronOreForecastScraper")
        print("  scraper = IronOreForecastScraper()")
        print("  scraper.scrape_urls(['url1', 'url2', ...])")
        print("  scraper.export_to_csv('output.csv')")
