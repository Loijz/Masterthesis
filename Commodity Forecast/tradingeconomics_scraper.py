"""
Trading Economics Scraper - Iron Ore Forecasts
Same algorithm as mining.com and capital.com
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def extract_article_urls(soup, base_url):
    """Extract article URLs from Trading Economics page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for Trading Economics content
        if 'tradingeconomics.com' in url and url not in urls:
            # Exclude non-content pages
            exclude_patterns = [
                '/login', '/register', '/subscribe', '/pricing',
                '/contact', '/about', '/api', '/analytics',
                '/user/', '/account/', '/settings/'
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Include forecasts, news, articles
                if any(pattern in url for pattern in ['/forecast/', '/news/', '/commodity/', '/article/']):
                    urls.append(url)

    return urls


def get_direct_iron_ore_pages():
    """
    Get known iron ore pages from Trading Economics (EXPANDED)
    """
    print("\n" + "="*80)
    print("DIRECT IRON ORE PAGES - Trading Economics (EXPANDED)")
    print("="*80)

    # Expanded iron ore pages on Trading Economics
    iron_ore_pages = [
        # Main iron ore pages
        "https://tradingeconomics.com/commodity/iron-ore",
        "https://tradingeconomics.com/commodity/iron-ore/forecast",
        "https://tradingeconomics.com/iron-ore",

        # Historical data pages (different time ranges)
        "https://tradingeconomics.com/commodity/iron-ore:us",
        "https://tradingeconomics.com/commodity/iron-ore/historical",

        # News and articles
        "https://tradingeconomics.com/commodities/news",
        "https://tradingeconomics.com/commodity/metals",
        "https://tradingeconomics.com/commodities",

        # Related commodities (often discuss iron ore)
        "https://tradingeconomics.com/commodity/steel",
        "https://tradingeconomics.com/commodity/steel/forecast",

        # Regional pages (major iron ore markets)
        "https://tradingeconomics.com/china/indicators",
        "https://tradingeconomics.com/australia/indicators",
        "https://tradingeconomics.com/brazil/indicators",

        # Market analysis pages
        "https://tradingeconomics.com/markets/commodities",
        "https://tradingeconomics.com/forecast/commodity",

        # News by year (to find older content)
        "https://tradingeconomics.com/news/2023",
        "https://tradingeconomics.com/news/2022",
        "https://tradingeconomics.com/news/2021",
        "https://tradingeconomics.com/news/2020",
        "https://tradingeconomics.com/news/2019",
        "https://tradingeconomics.com/news/2018",
        "https://tradingeconomics.com/news/2017",
        "https://tradingeconomics.com/news/2016",
        "https://tradingeconomics.com/news/2015",
        "https://tradingeconomics.com/news/2014",
        "https://tradingeconomics.com/news/2013",
    ]

    print(f"\nDirect iron ore pages to check: {len(iron_ore_pages)}")
    print(f"  Including historical news from 2013-2023")

    return iron_ore_pages


def search_tradingeconomics(max_pages=20):
    """
    Search Trading Economics for iron ore content
    """
    print("\n" + "#"*80)
    print("# TRADING ECONOMICS IRON ORE SCRAPER")
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
        "https://tradingeconomics.com/commodities",
        "https://tradingeconomics.com/commodity",
        "https://tradingeconomics.com/markets/commodities",
    ]

    for section in commodities_sections:
        print(f"\nChecking: {section}")

        try:
            response = session.get(section, timeout=30)

            if response.status_code == 403:
                print(f"  Access forbidden (403)")
                continue

            if response.status_code == 405:
                print(f"  Method not allowed (405) - trying alternative")
                continue

            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Find links related to iron ore
            for link in soup.find_all('a', href=True):
                href = link.get('href')
                text = link.get_text().lower()

                if 'iron' in href.lower() or 'iron' in text or 'ore' in text:
                    full_url = urljoin(section, href)
                    if 'tradingeconomics.com' in full_url:
                        all_urls.add(full_url)

            print(f"  Found {len(all_urls)} total URLs so far")
            time.sleep(2)

        except Exception as e:
            print(f"  Error: {e}")

    # Strategy 3: Crawl each starting page for more links
    print("\n" + "="*80)
    print("STRATEGY 3: Deep Crawl - Find Sublinks")
    print("="*80)

    print(f"\nCrawling {len(all_urls)} pages to find sublinks...")

    urls_to_crawl = list(all_urls.copy())
    crawled = set()

    for i, page_url in enumerate(urls_to_crawl[:50], 1):  # Limit to first 50 to avoid too long
        if page_url in crawled:
            continue

        print(f"[{i}/50] Crawling: {page_url[:60]}... ", end='', flush=True)
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

                if any(kw in href.lower() or kw in text for kw in ['iron', 'ore', 'commodity', 'forecast']):
                    full_url = urljoin(page_url, href)
                    if 'tradingeconomics.com' in full_url:
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

    # Strategy 4: Search for iron ore articles/news
    print("\n" + "="*80)
    print("STRATEGY 4: News & Articles Search")
    print("="*80)

    search_urls = [
        "https://tradingeconomics.com/search?q=iron+ore",
        "https://tradingeconomics.com/search?q=iron+ore+forecast",
        "https://tradingeconomics.com/search?q=iron+ore+price",
        "https://tradingeconomics.com/news",
    ]

    for search_url in search_urls:
        print(f"\nSearching: {search_url}")

        try:
            response = session.get(search_url, timeout=30)

            if response.status_code >= 400:
                print(f"  Error {response.status_code}")
                continue

            soup = BeautifulSoup(response.content, 'html.parser')

            urls = extract_article_urls(soup, search_url)
            iron_ore_urls = [u for u in urls if 'iron' in u.lower() or 'ore' in u.lower()]

            all_urls.update(iron_ore_urls)
            print(f"  Found {len(iron_ore_urls)} iron ore URLs")

            time.sleep(2)

        except Exception as e:
            print(f"  Error: {e}")

    all_urls = list(all_urls)

    print(f"\n{'='*80}")
    print(f"SEARCH COMPLETE")
    print(f"{'='*80}")
    print(f"Total unique URLs found: {len(all_urls)}")

    if not all_urls:
        print("\n⚠ No URLs found")
        print("\nPossible reasons:")
        print("  - Trading Economics may be blocking automated requests")
        print("  - Site structure may have changed")
        print("\nAlternatives:")
        print("  1. Manually browse tradingeconomics.com/commodity/iron-ore")
        print("  2. Copy specific URLs to a text file")
        print("  3. Use scrape_from_file.py to scrape them")
        return [], None

    # Save URLs
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    filename = f'tradingeconomics_urls_{timestamp}.txt'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# Trading Economics Iron Ore URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(all_urls)}\n")
        f.write("#\n")
        for url in sorted(all_urls):
            f.write(url + '\n')

    print(f"\n✅ Saved {len(all_urls)} URLs to '{filename}'")

    # Show URLs
    print(f"\nURLs found:")
    for i, url in enumerate(sorted(all_urls), 1):
        print(f"{i}. {url}")

    return all_urls, filename


def scrape_tradingeconomics_urls(url_file):
    """
    Scrape Trading Economics URLs for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING TRADING ECONOMICS URLs")
    print("="*80)

    try:
        with open(url_file, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

        print(f"\nLoaded {len(urls)} URLs from {url_file}")

        response = input("\nProceed with scraping? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled")
            return

        from iron_ore_scraper import IronOreForecastScraper

        start_time = datetime.now()
        scraper = IronOreForecastScraper()

        for i, url in enumerate(urls, 1):
            print(f"\n[{i}/{len(urls)}] {url}")
            scraper.scrape_url(url)

            if i % 3 == 0:
                print(f"  → Forecasts found so far: {len(scraper.forecasts)}")

        elapsed = (datetime.now() - start_time).total_seconds()

        # Export
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        csv_file = f'tradingeconomics_forecasts_{timestamp}.csv'
        json_file = f'tradingeconomics_forecasts_{timestamp}.json'

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
    print("# TRADING ECONOMICS IRON ORE SCRAPER")
    print("#"*80)
    print("\nTrading Economics provides:")
    print("  - Iron ore price data and forecasts")
    print("  - Economic indicators")
    print("  - Commodity market analysis\n")

    print("What would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_tradingeconomics()

        if urls:
            print(f"\n✅ URLs collected: {len(urls)}")
            print(f"Saved to: {filename}")

    elif choice == "2":
        import os
        url_files = [f for f in os.listdir('.') if f.startswith('tradingeconomics_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound: {url_files[0]}")
            scrape_tradingeconomics_urls(url_files[0])
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_tradingeconomics_urls(filename)

    elif choice == "3":
        urls, filename = search_tradingeconomics()
        if urls:
            scrape_tradingeconomics_urls(filename)


if __name__ == "__main__":
    main()
