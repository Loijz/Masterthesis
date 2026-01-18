"""
IndexMundi Scraper - Iron Ore Forecasts and Data
Same expanded approach as Trading Economics
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def extract_article_urls(soup, base_url):
    """Extract article URLs from IndexMundi page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for IndexMundi content
        if 'indexmundi.com' in url and url not in urls:
            # Exclude non-content pages
            exclude_patterns = [
                '/login', '/register', '/contact', '/about',
                '/privacy', '/terms', '/sitemap', '/rss'
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Include commodity, forecast, data pages
                if any(pattern in url for pattern in ['/commodities/', '/commodity=', '/graph', '/data', '/forecast']):
                    urls.append(url)

    return urls


def get_direct_iron_ore_pages():
    """
    Get known iron ore pages from IndexMundi (EXPANDED)
    """
    print("\n" + "="*80)
    print("DIRECT IRON ORE PAGES - IndexMundi (EXPANDED)")
    print("="*80)

    # Expanded iron ore pages on IndexMundi
    iron_ore_pages = [
        # Main iron ore pages
        "https://www.indexmundi.com/commodities/?commodity=iron-ore",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=360",  # 30 years
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=240",  # 20 years
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=120",  # 10 years
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=60",   # 5 years

        # Historical data by year
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2023",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2022",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2021",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2020",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2019",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2018",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2017",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2016",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2015",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2014",
        "https://www.indexmundi.com/commodities/?commodity=iron-ore&months=12&year=2013",

        # Charts and graphs
        "https://www.indexmundi.com/commodities/minerals/iron-ore/iron-ore_monthly.aspx",
        "https://www.indexmundi.com/commodities/minerals/iron-ore/iron-ore_daily.aspx",

        # Main commodities page
        "https://www.indexmundi.com/commodities/",
        "https://www.indexmundi.com/commodities/minerals/",

        # Related commodities
        "https://www.indexmundi.com/commodities/?commodity=steel",
        "https://www.indexmundi.com/commodities/?commodity=steel&months=120",

        # Country pages (major producers/consumers)
        "https://www.indexmundi.com/australia/economy_profile.html",
        "https://www.indexmundi.com/china/economy_profile.html",
        "https://www.indexmundi.com/brazil/economy_profile.html",

        # Background and analysis
        "https://www.indexmundi.com/commodities/minerals/iron-ore",
        "https://www.indexmundi.com/minerals/",
    ]

    print(f"\nDirect pages to check: {len(iron_ore_pages)}")
    print(f"  Including historical data from 2013-2023")
    print(f"  Multiple timeframes (5, 10, 20, 30 years)")

    return iron_ore_pages


def search_indexmundi(max_crawl=50):
    """
    Search IndexMundi for iron ore content (EXPANDED)
    """
    print("\n" + "#"*80)
    print("# INDEXMUNDI IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
    })

    all_urls = set()

    # Strategy 1: Direct iron ore pages
    print("\n" + "="*80)
    print("STRATEGY 1: Known Iron Ore Pages")
    print("="*80)

    direct_pages = get_direct_iron_ore_pages()
    all_urls.update(direct_pages)

    # Strategy 2: Commodities section
    print("\n" + "="*80)
    print("STRATEGY 2: Commodities Section")
    print("="*80)

    commodities_sections = [
        "https://www.indexmundi.com/commodities/",
        "https://www.indexmundi.com/commodities/minerals/",
        "https://www.indexmundi.com/minerals/",
    ]

    for section in commodities_sections:
        print(f"\nChecking: {section}")

        try:
            response = session.get(section, timeout=30)

            if response.status_code >= 400:
                print(f"  Error {response.status_code}")
                continue

            soup = BeautifulSoup(response.content, 'html.parser')

            # Find links related to iron ore
            for link in soup.find_all('a', href=True):
                href = link.get('href')
                text = link.get_text().lower()

                if any(kw in href.lower() or kw in text for kw in ['iron', 'ore', 'steel']):
                    full_url = urljoin(section, href)
                    if 'indexmundi.com' in full_url:
                        all_urls.add(full_url)

            print(f"  Found {len(all_urls)} total URLs so far")
            time.sleep(2)

        except Exception as e:
            print(f"  Error: {e}")

    # Strategy 3: Deep Crawl - Find Sublinks
    print("\n" + "="*80)
    print("STRATEGY 3: Deep Crawl - Find Sublinks")
    print("="*80)

    print(f"\nCrawling {min(len(all_urls), max_crawl)} pages to find sublinks...")

    urls_to_crawl = list(all_urls.copy())
    crawled = set()

    for i, page_url in enumerate(urls_to_crawl[:max_crawl], 1):
        if page_url in crawled:
            continue

        print(f"[{i}/{max_crawl}] Crawling: {page_url[:60]}... ", end='', flush=True)
        crawled.add(page_url)

        try:
            response = session.get(page_url, timeout=30)

            if response.status_code >= 400:
                print(f"error {response.status_code}")
                continue

            soup = BeautifulSoup(response.content, 'html.parser')

            # Find all links on this page
            page_links = extract_article_urls(soup, page_url)

            # Also look for iron ore mentions
            for link in soup.find_all('a', href=True):
                href = link.get('href')
                text = link.get_text().lower()

                if any(kw in href.lower() or kw in text for kw in ['iron', 'ore', 'commodity', 'mineral', 'steel']):
                    full_url = urljoin(page_url, href)
                    if 'indexmundi.com' in full_url:
                        page_links.append(full_url)

            new_links = [u for u in page_links if u not in all_urls]

            if new_links:
                all_urls.update(new_links)
                print(f"found {len(new_links)} new links (total: {len(all_urls)})")
            else:
                print(f"no new links")

            time.sleep(1.5)

        except Exception as e:
            print(f"error: {e}")

    # Strategy 4: Time-based pages (monthly/yearly data)
    print("\n" + "="*80)
    print("STRATEGY 4: Time-Based Data Pages")
    print("="*80)

    print("\nGenerating time-series URLs...")

    # Generate URLs for different time periods
    for year in range(2013, 2026):
        for months in [1, 3, 6, 12]:
            url = f"https://www.indexmundi.com/commodities/?commodity=iron-ore&months={months}&year={year}"
            all_urls.add(url)

    # Different month ranges for historical view
    for months in [24, 36, 48, 60, 120, 180, 240, 360]:
        url = f"https://www.indexmundi.com/commodities/?commodity=iron-ore&months={months}"
        all_urls.add(url)

    print(f"  Added time-series URLs (total: {len(all_urls)})")

    all_urls = list(all_urls)

    print(f"\n{'='*80}")
    print(f"SEARCH COMPLETE")
    print(f"{'='*80}")
    print(f"Total unique URLs found: {len(all_urls)}")

    if not all_urls:
        print("\n⚠ No URLs found")
        return [], None

    # Save URLs
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    filename = f'indexmundi_urls_{timestamp}.txt'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# IndexMundi Iron Ore URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(all_urls)}\n")
        f.write(f"# Coverage: 2013-2025, multiple timeframes\n")
        f.write("#\n")
        for url in sorted(all_urls):
            f.write(url + '\n')

    print(f"\n✅ Saved {len(all_urls)} URLs to '{filename}'")

    # Show sample
    print(f"\nSample URLs (first 15):")
    for i, url in enumerate(sorted(all_urls)[:15], 1):
        print(f"{i:2d}. {url}")

    if len(all_urls) > 15:
        print(f"... and {len(all_urls) - 15} more")

    return all_urls, filename


def scrape_indexmundi_urls(url_file):
    """
    Scrape IndexMundi URLs for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING INDEXMUNDI URLs")
    print("="*80)

    try:
        with open(url_file, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

        print(f"\nLoaded {len(urls)} URLs from {url_file}")

        # Estimate
        estimated_time = len(urls) * 1.5
        print(f"Estimated time: {estimated_time/60:.0f} minutes ({estimated_time/3600:.1f} hours)")

        response = input("\nProceed with scraping? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled")
            return

        from iron_ore_scraper import IronOreForecastScraper

        start_time = datetime.now()
        scraper = IronOreForecastScraper()

        for i, url in enumerate(urls, 1):
            print(f"\n[{i}/{len(urls)}] {url[:80]}...")
            scraper.scrape_url(url)

            if i % 10 == 0:
                elapsed = (datetime.now() - start_time).total_seconds()
                print(f"  Progress: {i/len(urls)*100:.1f}% | Forecasts: {len(scraper.forecasts)} | Time: {elapsed/60:.1f}min")

        elapsed = (datetime.now() - start_time).total_seconds()

        # Export
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        csv_file = f'indexmundi_forecasts_{timestamp}.csv'
        json_file = f'indexmundi_forecasts_{timestamp}.json'

        scraper.print_summary()
        scraper.export_to_csv(csv_file)
        scraper.export_to_json(json_file)

        print("\n" + "="*80)
        print("✅ SCRAPING COMPLETE!")
        print("="*80)
        print(f"Time: {elapsed/60:.1f} minutes")
        print(f"\nFiles created:")
        print(f"  - {csv_file} ({len(scraper.forecasts)} forecasts)")
        print(f"  - {json_file}")

        if scraper.forecasts:
            prices = [f.price_usd for f in scraper.forecasts if f.price_usd]
            if prices:
                print(f"\nPrice statistics:")
                print(f"  Count: {len(prices)}")
                print(f"  Range: ${min(prices):.2f} - ${max(prices):.2f}")

    except FileNotFoundError:
        print(f"Error: File '{url_file}' not found")
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Main workflow"""
    print("\n" + "#"*80)
    print("# INDEXMUNDI IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)
    print("\nIndexMundi provides:")
    print("  - Historical commodity price data")
    print("  - Time-series charts and graphs")
    print("  - Country economic profiles")
    print("  - Coverage back to 2013 and earlier\n")

    print("Configuration:")
    print("  - Deep crawl pages: 50 (default)")
    print("  - Time coverage: 2013-2025")
    print("  - Multiple timeframes: 1m, 3m, 6m, 1y, 5y, 10y, 20y, 30y\n")

    crawl_pages = input("Max pages to crawl (default 50): ").strip()
    max_crawl = int(crawl_pages) if crawl_pages.isdigit() else 50

    print("\nWhat would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_indexmundi(max_crawl)

        if urls:
            print(f"\n✅ URLs collected: {len(urls)}")
            print(f"Saved to: {filename}")

    elif choice == "2":
        import os
        url_files = [f for f in os.listdir('.') if f.startswith('indexmundi_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound: {url_files[0]}")
            scrape_indexmundi_urls(url_files[0])
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_indexmundi_urls(filename)

    elif choice == "3":
        urls, filename = search_indexmundi(max_crawl)
        if urls:
            scrape_indexmundi_urls(filename)


if __name__ == "__main__":
    main()
