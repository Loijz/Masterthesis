"""
Quick Capital.com scraper - targets forecast sections directly
Based on debug output findings
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime
from iron_ore_scraper import IronOreForecastScraper


def scrape_capital_com_quick():
    """
    Quick approach based on debug findings
    """
    print("\n" + "="*80)
    print("CAPITAL.COM QUICK SCRAPER")
    print("="*80)

    # Known iron ore article
    known_articles = [
        "https://capital.com/en-au/analysis/iron-ore-price-forecast",
        "https://capital.com/en-gb/analysis/iron-ore-price-forecast",
        "https://capital.com/analysis/iron-ore-price-forecast",
    ]

    # Forecast category pages to search
    forecast_sections = [
        "https://capital.com/en-au/analysis/forecasts-and-predictions",
        "https://capital.com/en-gb/analysis/forecasts-and-predictions",
        "https://capital.com/analysis/commodities",
    ]

    all_urls = set(known_articles)

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    # Search forecast sections
    print("\nSearching forecast/commodities sections...")

    for section in forecast_sections:
        print(f"\n→ {section}")

        try:
            response = session.get(section, timeout=30)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Find all links
            for link in soup.find_all('a', href=True):
                href = link.get('href')
                full_url = urljoin(section, href)

                # Look for forecast/prediction articles
                if 'capital.com' in full_url and '/analysis/' in full_url:
                    # Add if it mentions commodities or forecasts
                    if any(kw in full_url.lower() for kw in ['forecast', 'prediction', 'commodity', 'commodities', 'iron', 'ore']):
                        all_urls.add(full_url)

            print(f"  Found {len(all_urls)} total URLs so far")
            time.sleep(1)

        except Exception as e:
            print(f"  Error: {e}")

    # Now check each URL for iron ore content
    print(f"\n{'='*80}")
    print(f"FILTERING {len(all_urls)} URLs FOR IRON ORE CONTENT")
    print(f"{'='*80}\n")

    iron_ore_urls = []

    for i, url in enumerate(all_urls, 1):
        print(f"[{i}/{len(all_urls)}] {url[:70]}... ", end='', flush=True)

        try:
            response = session.get(url, timeout=30)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Check for iron ore
            text = soup.get_text().lower()

            # Must have "iron ore" (not just "ore" or "iron")
            if 'iron ore' in text or 'iron-ore' in text:
                iron_ore_urls.append(url)
                print("✓ IRON ORE ARTICLE!")
            else:
                print("✗ not iron ore")

            time.sleep(0.5)

        except Exception as e:
            print(f"error: {e}")

    # Results
    print(f"\n{'='*80}")
    print(f"IRON ORE ARTICLES FOUND: {len(iron_ore_urls)}")
    print(f"{'='*80}\n")

    if iron_ore_urls:
        for i, url in enumerate(iron_ore_urls, 1):
            print(f"{i}. {url}")

        # Save
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        url_file = f'capital_com_iron_ore_{timestamp}.txt'

        with open(url_file, 'w', encoding='utf-8') as f:
            for url in iron_ore_urls:
                f.write(url + '\n')

        print(f"\n✓ Saved to '{url_file}'")

        # Scrape
        scrape = input("\nScrape these for forecast data? (y/n): ").strip().lower()

        if scrape == 'y':
            print("\nScraping for forecast data...")
            scraper = IronOreForecastScraper()

            for i, url in enumerate(iron_ore_urls, 1):
                print(f"\n[{i}/{len(iron_ore_urls)}] {url}")
                scraper.scrape_url(url)

            # Export
            csv_file = f'capital_com_forecasts_{timestamp}.csv'
            json_file = f'capital_com_forecasts_{timestamp}.json'

            scraper.print_summary()
            scraper.export_to_csv(csv_file)
            scraper.export_to_json(json_file)

            print(f"\n✅ Complete!")
            print(f"Files: {csv_file}, {json_file}")

    else:
        print("No iron ore articles found")


if __name__ == "__main__":
    scrape_capital_com_quick()
