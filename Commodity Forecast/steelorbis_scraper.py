"""
SteelOrbis Scraper - Iron Ore Prices, News, and Forecasts
Same expanded approach as other scrapers
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def extract_article_urls(soup, base_url):
    """Extract article URLs from SteelOrbis page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for SteelOrbis content
        if 'steelorbis.com' in url and url not in urls:
            # Exclude non-content pages
            exclude_patterns = [
                '/login', '/register', '/signup', '/subscribe',
                '/contact', '/about', '/privacy', '/terms',
                '/user', '/account', '/profile', '/settings'
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Include news, prices, markets, statistics
                if any(pattern in url for pattern in ['/steel-news/', '/steel-prices/', '/steel-market/',
                                                      '/statistics/', '/interviews/', '/steel-matters/',
                                                      '/latest-news/', '/weekly-steel-prices/',
                                                      '/daily-prices/', '/forecasters/']):
                    urls.append(url)

    return urls


def get_direct_iron_ore_pages():
    """
    Get known iron ore pages from SteelOrbis (EXPANDED)
    """
    print("\n" + "="*80)
    print("DIRECT IRON ORE PAGES - SteelOrbis (EXPANDED)")
    print("="*80)

    # Expanded SteelOrbis pages
    iron_ore_pages = [
        # Main iron ore page
        "https://www.steelorbis.com/steel-market/iron-ore.htm",

        # News sections
        "https://www.steelorbis.com/steel-news/latest-news/",
        "https://www.steelorbis.com/steel-news/interviews/",

        # Price sections
        "https://www.steelorbis.com/steel-prices/",
        "https://www.steelorbis.com/steel-prices/daily-prices/",
        "https://www.steelorbis.com/steel-prices/weekly-steel-prices/",
        "https://www.steelorbis.com/steel-prices/futures-prices/",

        # Market commentary
        "https://www.steelorbis.com/steel-prices/steel-matters/",

        # Regional markets (major iron ore producers/consumers)
        "https://www.steelorbis.com/steel-market/china.htm",
        "https://www.steelorbis.com/steel-market/australia.htm",
        "https://www.steelorbis.com/steel-market/brazil.htm",
        "https://www.steelorbis.com/steel-market/india.htm",
        "https://www.steelorbis.com/steel-market/usa.htm",
        "https://www.steelorbis.com/steel-market/turkey.htm",
        "https://www.steelorbis.com/steel-market/eu.htm",
        "https://www.steelorbis.com/steel-market/far-east.htm",
        "https://www.steelorbis.com/steel-market/cis.htm",

        # Statistics
        "https://www.steelorbis.com/statistics/production-consumption-data/",
        "https://www.steelorbis.com/statistics/import-export-statistics/",

        # Price forecasters
        "https://www.steelorbis.com/steel-prices/price-forecasters/",

        # Scrap (related to iron ore/steel)
        "https://www.steelorbis.com/steel-market/scrap.htm",

        # Product categories (often mention iron ore)
        "https://www.steelorbis.com/steel-market/rebar.htm",
        "https://www.steelorbis.com/steel-market/hrc.htm",
        "https://www.steelorbis.com/steel-market/crc.htm",
    ]

    print(f"\nDirect pages to check: {len(iron_ore_pages)}")
    print(f"  Including news, prices, regional markets, statistics")

    return iron_ore_pages


def search_steelorbis(max_crawl=50):
    """
    Search SteelOrbis for iron ore content (EXPANDED)
    """
    print("\n" + "#"*80)
    print("# STEELORBIS IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.steelorbis.com/',
    })

    all_urls = set()

    # Strategy 1: Direct iron ore pages
    print("\n" + "="*80)
    print("STRATEGY 1: Known Pages")
    print("="*80)

    direct_pages = get_direct_iron_ore_pages()
    all_urls.update(direct_pages)

    # Strategy 2: News sections with pagination
    print("\n" + "="*80)
    print("STRATEGY 2: News Sections (with pagination)")
    print("="*80)

    news_sections = [
        "https://www.steelorbis.com/steel-news/latest-news/",
        "https://www.steelorbis.com/steel-prices/steel-matters/",
    ]

    for section in news_sections:
        print(f"\nChecking: {section}")

        # Try multiple pages (pagination)
        for page in range(1, 11):  # First 10 pages
            if page == 1:
                page_url = section
            else:
                # SteelOrbis pagination pattern
                page_url = f"{section}?page={page}"

            try:
                response = session.get(page_url, timeout=30)

                if response.status_code >= 400:
                    if page == 1:
                        print(f"  Error {response.status_code}")
                    break

                soup = BeautifulSoup(response.content, 'html.parser')

                # Find article links
                page_links = extract_article_urls(soup, page_url)

                # Also look for iron ore mentions
                for link in soup.find_all('a', href=True):
                    href = link.get('href')
                    text = link.get_text().lower()

                    if any(kw in href.lower() or kw in text for kw in
                          ['iron', 'ore', 'iron-ore', 'ironore']):
                        full_url = urljoin(page_url, href)
                        if 'steelorbis.com' in full_url:
                            page_links.append(full_url)

                new_links = [u for u in page_links if u not in all_urls]

                if new_links:
                    all_urls.update(new_links)
                    print(f"  Page {page}: found {len(new_links)} new URLs (total: {len(all_urls)})")
                else:
                    if page > 1:
                        break

                time.sleep(1.5)

            except Exception as e:
                print(f"  Error on page {page}: {e}")
                break

    # Strategy 3: Regional markets
    print("\n" + "="*80)
    print("STRATEGY 3: Regional Markets")
    print("="*80)

    regions = ['china', 'australia', 'brazil', 'india', 'usa', 'turkey', 'eu', 'far-east', 'cis']

    for region in regions:
        market_url = f"https://www.steelorbis.com/steel-market/{region}.htm"
        print(f"\nChecking: {region.upper()}")

        try:
            response = session.get(market_url, timeout=30)

            if response.status_code >= 400:
                print(f"  Error {response.status_code}")
                continue

            soup = BeautifulSoup(response.content, 'html.parser')

            # Find links on regional page
            for link in soup.find_all('a', href=True):
                href = link.get('href')
                text = link.get_text().lower()

                if any(kw in href.lower() or kw in text for kw in
                      ['iron', 'ore', 'price', 'news', 'market']):
                    full_url = urljoin(market_url, href)
                    if 'steelorbis.com' in full_url:
                        all_urls.add(full_url)

            print(f"  Total URLs: {len(all_urls)}")
            time.sleep(1.5)

        except Exception as e:
            print(f"  Error: {e}")

    # Strategy 4: Deep Crawl - Find Sublinks
    print("\n" + "="*80)
    print("STRATEGY 4: Deep Crawl - Find Sublinks")
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

                if any(kw in href.lower() or kw in text for kw in
                      ['iron', 'ore', 'commodity', 'price', 'forecast', 'market']):
                    full_url = urljoin(page_url, href)
                    if 'steelorbis.com' in full_url:
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
    filename = f'steelorbis_urls_{timestamp}.txt'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# SteelOrbis Iron Ore URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(all_urls)}\n")
        f.write(f"# Focus: News, prices, regional markets, forecasts\n")
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


def scrape_steelorbis_urls(url_file):
    """
    Scrape SteelOrbis URLs for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING STEELORBIS URLs")
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
        csv_file = f'steelorbis_forecasts_{timestamp}.csv'
        json_file = f'steelorbis_forecasts_{timestamp}.json'

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
    print("# STEELORBIS IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)
    print("\nSteelOrbis provides:")
    print("  - Steel and iron ore market analysis")
    print("  - Daily and weekly price data")
    print("  - Regional market coverage (9+ regions)")
    print("  - Price forecasters and market commentary\n")

    print("Configuration:")
    print("  - Deep crawl pages: 50 (default)")
    print("  - News pagination: 10 pages per section")
    print("  - Regional markets: 9 regions\n")

    crawl_pages = input("Max pages to crawl (default 50): ").strip()
    max_crawl = int(crawl_pages) if crawl_pages.isdigit() else 50

    print("\nWhat would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_steelorbis(max_crawl)

        if urls:
            print(f"\n✅ URLs collected: {len(urls)}")
            print(f"Saved to: {filename}")

    elif choice == "2":
        import os
        url_files = [f for f in os.listdir('.') if f.startswith('steelorbis_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound: {url_files[0]}")
            scrape_steelorbis_urls(url_files[0])
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_steelorbis_urls(filename)

    elif choice == "3":
        urls, filename = search_steelorbis(max_crawl)
        if urls:
            scrape_steelorbis_urls(filename)


if __name__ == "__main__":
    main()
