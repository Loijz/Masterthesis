"""
Simple Capital.com Scraper
Direct approach - just scrape all analysis articles and filter by content
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def get_all_analysis_articles(base_url, max_pages=100):
    """
    Get ALL articles from capital.com analysis section
    Don't filter by URL - we'll filter by content later
    """
    print(f"\n{'='*80}")
    print(f"EXTRACTING ALL ANALYSIS ARTICLES")
    print(f"{'='*80}")
    print(f"Base URL: {base_url}")
    print(f"Max pages: {max_pages}\n")

    all_urls = set()

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    for page in range(1, max_pages + 1):
        # Try different pagination patterns
        page_urls = [
            base_url if page == 1 else f"{base_url}?page={page}",
            base_url if page == 1 else f"{base_url}/page/{page}",
        ]

        success = False

        for page_url in page_urls:
            if success:
                break

            print(f"Page {page}/{max_pages}: Trying {page_url[:80]}... ", end='', flush=True)

            try:
                response = session.get(page_url, timeout=30)

                if response.status_code == 404:
                    print("404, trying next pattern")
                    continue

                response.raise_for_status()
                soup = BeautifulSoup(response.content, 'html.parser')

                # Find all links
                page_article_urls = set()

                for link in soup.find_all('a', href=True):
                    href = link.get('href')
                    full_url = urljoin(base_url, href)

                    # Very simple filter - just get capital.com analysis links
                    if 'capital.com' in full_url and '/analysis/' in full_url:
                        # Exclude obvious non-articles
                        if not any(x in full_url for x in ['/login', '/signup', '/account', '#']):
                            page_article_urls.add(full_url)

                new_urls = page_article_urls - all_urls

                if len(new_urls) > 0:
                    all_urls.update(new_urls)
                    print(f"found {len(new_urls)} new URLs (total: {len(all_urls)})")
                    success = True
                else:
                    if page == 1:
                        print(f"no articles, trying next pattern")
                    else:
                        print(f"no new articles, stopping")
                        return list(all_urls)

                time.sleep(1)

            except Exception as e:
                print(f"error: {e}")
                continue

        if not success:
            print(f"\nNo more pages found, stopping at page {page}")
            break

    print(f"\n→ Total unique article URLs: {len(all_urls)}")
    return list(all_urls)


def filter_for_iron_ore_content(urls):
    """
    Check each URL's content for iron ore keywords
    This is slower but more accurate
    """
    print(f"\n{'='*80}")
    print(f"FILTERING {len(urls)} ARTICLES FOR IRON ORE CONTENT")
    print(f"{'='*80}\n")

    iron_ore_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    for i, url in enumerate(urls, 1):
        print(f"[{i}/{len(urls)}] Checking: {url[:70]}... ", end='', flush=True)

        try:
            response = session.get(url, timeout=30)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Get page text
            page_text = soup.get_text().lower()
            title = soup.find('title')
            title_text = title.get_text().lower() if title else ""

            # Check for iron ore content
            has_iron_ore = 'iron ore' in page_text or 'iron-ore' in page_text or 'iron ore' in url.lower()

            # Check for forecast content
            forecast_keywords = ['forecast', 'prediction', 'outlook', 'expect', 'price']
            has_forecast = any(kw in page_text or kw in title_text for kw in forecast_keywords)

            if has_iron_ore and has_forecast:
                iron_ore_urls.append(url)
                print(f"✓ MATCH!")
            else:
                status = []
                if not has_iron_ore:
                    status.append("no iron ore")
                if not has_forecast:
                    status.append("no forecast")
                print(f"✗ ({', '.join(status)})")

            time.sleep(0.5)  # Be polite

        except Exception as e:
            print(f"error: {e}")

    print(f"\n{'='*80}")
    print(f"FILTERING COMPLETE")
    print(f"{'='*80}")
    print(f"Total articles checked: {len(urls)}")
    print(f"Iron ore forecast articles found: {len(iron_ore_urls)}")

    return iron_ore_urls


def scrape_capital_com_simple():
    """
    Simple workflow for capital.com
    """
    print("\n" + "#"*80)
    print("# SIMPLE CAPITAL.COM SCRAPER")
    print("#"*80)
    print("\nStrategy:")
    print("  1. Get ALL analysis articles (don't filter by URL)")
    print("  2. Check each article's content for iron ore + forecast")
    print("  3. Scrape the matches\n")

    # Define regions to search
    regions = {
        "Australia": "https://capital.com/en-au/analysis",
        "UK": "https://capital.com/en-gb/analysis",
        "Global": "https://capital.com/analysis",
    }

    print("Available regions:")
    for i, (name, url) in enumerate(regions.items(), 1):
        print(f"  {i}. {name}: {url}")

    choice = input("\nSearch all regions? (y/n): ").strip().lower()

    if choice == 'y':
        selected_regions = list(regions.items())
    else:
        num = input("Enter region number (1-3): ").strip()
        region_list = list(regions.items())
        selected_regions = [region_list[int(num)-1]] if num.isdigit() and 0 < int(num) <= 3 else region_list[:1]

    max_pages = input("\nMax pages per region (default 50): ").strip()
    max_pages = int(max_pages) if max_pages.isdigit() else 50

    # Step 1: Get all analysis articles
    all_urls = []

    for name, url in selected_regions:
        print(f"\n{'='*80}")
        print(f"REGION: {name}")
        print(f"{'='*80}")

        urls = get_all_analysis_articles(url, max_pages=max_pages)
        all_urls.extend(urls)

        print(f"✓ Found {len(urls)} articles from {name}")

    # Remove duplicates
    all_urls = list(set(all_urls))

    print(f"\n{'='*80}")
    print(f"Total unique articles across all regions: {len(all_urls)}")
    print(f"{'='*80}")

    if not all_urls:
        print("\n✗ No articles found. Check the debug output.")
        return

    # Save all URLs first
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    all_urls_file = f'capital_com_all_analysis_{timestamp}.txt'

    with open(all_urls_file, 'w', encoding='utf-8') as f:
        for url in sorted(all_urls):
            f.write(url + '\n')

    print(f"✓ Saved all {len(all_urls)} URLs to '{all_urls_file}'")

    # Step 2: Filter for iron ore content
    filter_choice = input("\nFilter for iron ore content now? (y/n): ").strip().lower()

    if filter_choice == 'y':
        iron_ore_urls = filter_for_iron_ore_content(all_urls)

        if iron_ore_urls:
            # Save iron ore URLs
            iron_ore_file = f'capital_com_iron_ore_urls_{timestamp}.txt'
            with open(iron_ore_file, 'w', encoding='utf-8') as f:
                for url in iron_ore_urls:
                    f.write(url + '\n')

            print(f"\n✓ Saved {len(iron_ore_urls)} iron ore URLs to '{iron_ore_file}'")

            # Show sample
            print(f"\nIron ore articles found:")
            for i, url in enumerate(iron_ore_urls, 1):
                print(f"{i}. {url}")

            # Step 3: Scrape them
            scrape_choice = input("\nScrape these articles for forecast data? (y/n): ").strip().lower()

            if scrape_choice == 'y':
                from iron_ore_scraper import IronOreForecastScraper

                print("\nScraping for forecast data...")
                scraper = IronOreForecastScraper()
                scraper.scrape_urls(iron_ore_urls)

                # Export
                csv_file = f'capital_com_forecasts_{timestamp}.csv'
                json_file = f'capital_com_forecasts_{timestamp}.json'

                scraper.print_summary()
                scraper.export_to_csv(csv_file)
                scraper.export_to_json(json_file)

                print(f"\n✅ Complete! Files created:")
                print(f"  - {csv_file}")
                print(f"  - {json_file}")

        else:
            print("\n✗ No iron ore articles found after filtering")
    else:
        print(f"\nURLs saved to '{all_urls_file}'")
        print("You can filter them later by running this script again")


def main():
    print("\n" + "#"*80)
    print("# CAPITAL.COM SIMPLE SCRAPER")
    print("#"*80)
    print("\nThis version:")
    print("  - Gets ALL analysis articles first")
    print("  - Then filters by checking actual content")
    print("  - More reliable but slower\n")

    scrape_capital_com_simple()


if __name__ == "__main__":
    main()
