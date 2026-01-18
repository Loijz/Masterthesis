"""
GMK Center Scraper - Steel and Iron Ore Market Analytics
Same expanded approach as other scrapers
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def extract_article_urls(soup, base_url):
    """Extract article URLs from GMK Center page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for GMK Center content
        if 'gmk.center' in url and url not in urls:
            # Exclude non-content pages
            exclude_patterns = [
                '/login', '/register', '/signup', '/subscribe',
                '/contact', '/about', '/privacy', '/terms',
                '/user', '/account', '/profile', '/ru/'  # Exclude Russian version
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Include news, analytics, interviews, posts
                if any(pattern in url for pattern in ['/en/news/', '/en/analitycs/', '/en/interview/',
                                                      '/en/posts/', '/en/opinion/', '/en/infographic/',
                                                      '/en/companies/', '/en/global-market/',
                                                      '/en/industry/', '/en/technologies/']):
                    urls.append(url)

    return urls


def get_direct_iron_ore_pages():
    """
    Get known iron ore pages from GMK Center (EXPANDED)
    """
    print("\n" + "="*80)
    print("DIRECT IRON ORE PAGES - GMK Center (EXPANDED)")
    print("="*80)

    # Expanded GMK Center pages
    iron_ore_pages = [
        # Main sections
        "https://gmk.center/en/",
        "https://gmk.center/en/news/",
        "https://gmk.center/en/analitycs/",  # Note: site uses "analitycs" spelling

        # Content types
        "https://gmk.center/en/interview/",
        "https://gmk.center/en/posts/",
        "https://gmk.center/en/opinion/",
        "https://gmk.center/en/infographic/",

        # Topic categories
        "https://gmk.center/en/news/companies/",
        "https://gmk.center/en/news/global-market/",
        "https://gmk.center/en/news/industry/",
        "https://gmk.center/en/news/technologies/",
        "https://gmk.center/en/news/ecology/",
        "https://gmk.center/en/news/green-steel/",
        "https://gmk.center/en/news/infrastructure/",
        "https://gmk.center/en/news/state/",

        # Analytics categories
        "https://gmk.center/en/analitycs/companies/",
        "https://gmk.center/en/analitycs/global-market/",
        "https://gmk.center/en/analitycs/industry/",

        # Services (might have reports)
        "https://gmk.center/en/consulting/",
        "https://gmk.center/en/sustainability/",
    ]

    print(f"\nDirect pages to check: {len(iron_ore_pages)}")
    print(f"  Including news, analytics, interviews, opinions")

    return iron_ore_pages


def search_gmkcenter(max_crawl=50):
    """
    Search GMK Center for iron ore content (EXPANDED)
    """
    print("\n" + "#"*80)
    print("# GMK CENTER IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://gmk.center/en/',
    })

    all_urls = set()

    # Strategy 1: Direct pages
    print("\n" + "="*80)
    print("STRATEGY 1: Known Pages")
    print("="*80)

    direct_pages = get_direct_iron_ore_pages()
    all_urls.update(direct_pages)

    # Strategy 2: News sections with pagination
    print("\n" + "="*80)
    print("STRATEGY 2: News Sections (with pagination)")
    print("="*80)

    news_categories = [
        'companies', 'global-market', 'industry', 'technologies',
        'ecology', 'green-steel', 'infrastructure'
    ]

    for category in news_categories:
        category_url = f"https://gmk.center/en/news/{category}/"
        print(f"\nChecking: {category}")

        # Try multiple pages (pagination)
        for page in range(1, 6):  # First 5 pages per category
            if page == 1:
                page_url = category_url
            else:
                # GMK Center pagination pattern (may vary)
                page_url = f"{category_url}?page={page}"

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
                          ['iron', 'ore', 'iron-ore', 'ironore', 'steel', 'mining']):
                        full_url = urljoin(page_url, href)
                        if 'gmk.center/en/' in full_url:
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

    # Strategy 3: Analytics sections with pagination
    print("\n" + "="*80)
    print("STRATEGY 3: Analytics Sections")
    print("="*80)

    analytics_categories = ['companies', 'global-market', 'industry']

    for category in analytics_categories:
        category_url = f"https://gmk.center/en/analitycs/{category}/"
        print(f"\nChecking analytics: {category}")

        for page in range(1, 6):  # First 5 pages
            if page == 1:
                page_url = category_url
            else:
                page_url = f"{category_url}?page={page}"

            try:
                response = session.get(page_url, timeout=30)

                if response.status_code >= 400:
                    break

                soup = BeautifulSoup(response.content, 'html.parser')

                page_links = extract_article_urls(soup, page_url)

                # Look for iron ore/steel content
                for link in soup.find_all('a', href=True):
                    href = link.get('href')
                    text = link.get_text().lower()

                    if any(kw in href.lower() or kw in text for kw in
                          ['iron', 'ore', 'steel', 'mining', 'market']):
                        full_url = urljoin(page_url, href)
                        if 'gmk.center/en/' in full_url:
                            page_links.append(full_url)

                new_links = [u for u in page_links if u not in all_urls]

                if new_links:
                    all_urls.update(new_links)
                    print(f"  Page {page}: {len(new_links)} new URLs (total: {len(all_urls)})")
                else:
                    if page > 1:
                        break

                time.sleep(1.5)

            except Exception as e:
                print(f"  Error: {e}")
                break

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
                      ['iron', 'ore', 'steel', 'mining', 'commodity', 'price', 'market', 'forecast']):
                    full_url = urljoin(page_url, href)
                    if 'gmk.center/en/' in full_url:
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
    filename = f'gmkcenter_urls_{timestamp}.txt'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# GMK Center Iron Ore URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(all_urls)}\n")
        f.write(f"# Focus: Steel market analytics, iron ore news\n")
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


def scrape_gmkcenter_urls(url_file):
    """
    Scrape GMK Center URLs for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING GMK CENTER URLs")
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
        csv_file = f'gmkcenter_forecasts_{timestamp}.csv'
        json_file = f'gmkcenter_forecasts_{timestamp}.json'

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
    print("# GMK CENTER IRON ORE SCRAPER (EXPANDED)")
    print("#"*80)
    print("\nGMK Center provides:")
    print("  - Steel and mining industry analytics (Ukraine-based)")
    print("  - Global market news and analysis")
    print("  - Company profiles and market insights")
    print("  - Green steel and sustainability coverage\n")

    print("Configuration:")
    print("  - Deep crawl pages: 50 (default)")
    print("  - News pagination: 5 pages per category (7 categories)")
    print("  - Analytics pagination: 5 pages per section (3 sections)\n")

    crawl_pages = input("Max pages to crawl (default 50): ").strip()
    max_crawl = int(crawl_pages) if crawl_pages.isdigit() else 50

    print("\nWhat would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_gmkcenter(max_crawl)

        if urls:
            print(f"\n✅ URLs collected: {len(urls)}")
            print(f"Saved to: {filename}")

    elif choice == "2":
        import os
        url_files = [f for f in os.listdir('.') if f.startswith('gmkcenter_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound: {url_files[0]}")
            scrape_gmkcenter_urls(url_files[0])
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_gmkcenter_urls(filename)

    elif choice == "3":
        urls, filename = search_gmkcenter(max_crawl)
        if urls:
            scrape_gmkcenter_urls(filename)


if __name__ == "__main__":
    main()
