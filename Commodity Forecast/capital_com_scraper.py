"""
Capital.com Iron Ore Forecast Scraper
Same approach as mining.com, adapted for capital.com structure
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def extract_article_urls(soup, base_url):
    """Extract article URLs from a capital.com page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for capital.com articles
        if 'capital.com' in url and url not in urls:
            # Exclude non-article pages
            exclude_patterns = [
                '/login', '/signup', '/register', '/account',
                '/contact', '/about', '/privacy', '/terms',
                '/cookie', '/help', '/faq', '/support',
                '/trading-platforms', '/pricing', '/pro-account',
                '/api', '/demo', '/open-account'
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Include analysis articles, market guides, news
                if '/analysis/' in url or '/market-guides/' in url or '/news/' in url:
                    urls.append(url)

    return urls


def get_urls_from_category(category_url, max_pages=50):
    """
    Get all article URLs from a capital.com category with pagination

    Args:
        category_url: The category page URL
        max_pages: Maximum number of pages to check
    """
    print(f"\n{'='*80}")
    print(f"Extracting URLs from: {category_url}")
    print(f"Max pages to check: {max_pages}")
    print(f"{'='*80}")

    all_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    for page in range(1, max_pages + 1):
        # Capital.com pagination patterns (may vary)
        if page == 1:
            page_url = category_url
        else:
            # Try common pagination patterns
            page_url = f"{category_url}?page={page}"

        print(f"  Page {page}/{max_pages}: ", end='', flush=True)

        try:
            response = session.get(page_url, timeout=30)

            if response.status_code == 404:
                print(f"doesn't exist, stopping")
                break

            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract article URLs
            page_urls = extract_article_urls(soup, category_url)

            # Remove duplicates
            new_urls = [u for u in page_urls if u not in all_urls]

            if len(new_urls) > 0:
                all_urls.extend(new_urls)
                print(f"found {len(new_urls)} URLs (total: {len(all_urls)})")
            else:
                print(f"no new articles found, stopping")
                break

            time.sleep(1)  # Be polite

        except Exception as e:
            print(f"error: {e}")
            break

    print(f"\n→ Total unique URLs from this category: {len(all_urls)}")
    return all_urls


def search_capital_com_categories(pages_per_category=50):
    """
    Search capital.com categories for iron ore content

    Args:
        pages_per_category: How many pages to check in each category
    """
    print("\n" + "#"*80)
    print("# CAPITAL.COM IRON ORE SCRAPER")
    print("#"*80)
    print(f"\nConfiguration:")
    print(f"  - Pages per category: {pages_per_category}")
    print(f"  - Delay between pages: 1 second")

    # Capital.com might have regional variants (en-au, en-gb, etc.)
    # We'll search multiple regions for broader coverage
    categories = {
        # Analysis sections (most likely to have forecasts)
        "1. Analysis (AU)": "https://capital.com/en-au/analysis",
        "2. Analysis (UK)": "https://capital.com/en-gb/analysis",
        "3. Analysis (US)": "https://capital.com/analysis",

        # Commodities sections
        "4. Commodities Analysis (AU)": "https://capital.com/en-au/analysis/commodities",
        "5. Commodities Analysis (UK)": "https://capital.com/en-gb/analysis/commodities",

        # Market guides
        "6. Market Guides Commodities": "https://capital.com/learn/market-guides/commodities",

        # News sections
        "7. Commodities News": "https://capital.com/news/commodities",

        # Search/tag pages if they exist
        "8. Iron Ore Tag (AU)": "https://capital.com/en-au/tag/iron-ore",
        "9. Iron Ore Tag (UK)": "https://capital.com/en-gb/tag/iron-ore",
    }

    start_time = datetime.now()
    all_urls = []

    print(f"\nSearching {len(categories)} categories...")
    print("="*80)

    for i, (name, url) in enumerate(categories.items(), 1):
        print(f"\n[{i}/{len(categories)}] Category: {name}")
        print(f"URL: {url}")

        urls = get_urls_from_category(url, max_pages=pages_per_category)

        if urls:
            all_urls.extend(urls)
            print(f"✓ Added {len(urls)} URLs from {name}")
        else:
            print(f"✗ No URLs found in {name}")

        # Progress update
        elapsed = (datetime.now() - start_time).total_seconds()
        print(f"Running for: {elapsed/60:.1f} minutes | Total URLs so far: {len(list(set(all_urls)))}")

        time.sleep(2)  # Be polite between categories

    # Remove duplicates
    all_urls = list(set(all_urls))

    elapsed = (datetime.now() - start_time).total_seconds()

    print(f"\n{'='*80}")
    print(f"SEARCH COMPLETE")
    print(f"{'='*80}")
    print(f"Total time: {elapsed/60:.1f} minutes")
    print(f"Categories searched: {len(categories)}")
    print(f"Total unique URLs found: {len(all_urls)}")

    # Filter for iron ore content
    print(f"\nFiltering for iron ore content...")
    iron_ore_urls = filter_iron_ore_urls(all_urls)

    # Save to file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    filename = f'capital_com_urls_{timestamp}.txt'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# Capital.com Iron Ore URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(iron_ore_urls)}\n")
        f.write(f"# Pages per category: {pages_per_category}\n")
        f.write("#\n")
        for url in sorted(iron_ore_urls):
            f.write(url + '\n')

    print(f"\n✅ Saved {len(iron_ore_urls)} iron ore URLs to '{filename}'")

    # Show sample
    print(f"\nSample URLs (first 10):")
    for i, url in enumerate(sorted(iron_ore_urls)[:10], 1):
        print(f"{i:2d}. {url}")

    if len(iron_ore_urls) > 10:
        print(f"... and {len(iron_ore_urls) - 10} more")

    return iron_ore_urls, filename


def filter_iron_ore_urls(all_urls):
    """
    Filter URLs to only those likely about iron ore
    """
    print(f"  URLs before filtering: {len(all_urls)}")

    iron_ore_keywords = [
        'iron-ore', 'iron_ore', 'ironore',
        'fe62', 'iron-ore-price', 'iron-ore-forecast',
        'commodity-forecast', 'commodities-forecast'
    ]

    filtered_urls = []

    for url in all_urls:
        url_lower = url.lower()
        if any(keyword in url_lower for keyword in iron_ore_keywords):
            filtered_urls.append(url)

    print(f"  URLs after filtering: {len(filtered_urls)}")
    print(f"  Filtered out: {len(all_urls) - len(filtered_urls)}")

    return filtered_urls


def scrape_capital_com_urls(url_file):
    """
    Scrape capital.com URLs for forecast data using the same scraper
    """
    print("\n" + "="*80)
    print("SCRAPING CAPITAL.COM URLs FOR FORECAST DATA")
    print("="*80)

    try:
        with open(url_file, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

        print(f"\nLoaded {len(urls)} URLs from {url_file}")

        # Estimate scraping time
        estimated_time = len(urls) * 1.5
        print(f"Estimated time: {estimated_time/60:.0f} minutes ({estimated_time/3600:.1f} hours)")

        response = input("\nProceed with scraping? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled")
            return

        print(f"\nScraping {len(urls)} URLs for forecast data...")

        # Use the same iron ore scraper
        from iron_ore_scraper import IronOreForecastScraper

        start_time = datetime.now()
        scraper = IronOreForecastScraper()

        # Scrape with progress updates
        for i, url in enumerate(urls, 1):
            print(f"\n[{i}/{len(urls)}] {url[:80]}...")
            scraper.scrape_url(url)

            # Show progress every 5 URLs
            if i % 5 == 0 or i == len(urls):
                elapsed = (datetime.now() - start_time).total_seconds()
                avg_time = elapsed / i
                remaining = len(urls) - i
                eta = remaining * avg_time

                print(f"  Progress: {i/len(urls)*100:.1f}% | "
                      f"Forecasts: {len(scraper.forecasts)} | "
                      f"Elapsed: {elapsed/60:.1f}min | "
                      f"ETA: {eta/60:.1f}min")

        elapsed = (datetime.now() - start_time).total_seconds()

        # Export results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        csv_file = f'capital_com_forecasts_{timestamp}.csv'
        json_file = f'capital_com_forecasts_{timestamp}.json'

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

        # Show statistics
        if scraper.forecasts:
            print(f"\nStatistics:")
            print(f"  Total forecasts: {len(scraper.forecasts)}")

            with_dates = sum(1 for f in scraper.forecasts if f.outlook_date)
            print(f"  With outlook dates: {with_dates}")

            prices = [f.price_usd for f in scraper.forecasts if f.price_usd]
            if prices:
                print(f"  With prices: {len(prices)}")
                print(f"  Price range: ${min(prices):.2f} - ${max(prices):.2f}")

    except FileNotFoundError:
        print(f"Error: File '{url_file}' not found")
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Main workflow for capital.com"""
    print("\n" + "#"*80)
    print("# CAPITAL.COM IRON ORE FORECAST SCRAPER")
    print("#"*80)
    print("\nSame algorithm as mining.com, adapted for capital.com")

    print("\nConfiguration options:")
    print("  - Conservative: 20 pages per category (~20-30 min)")
    print("  - Moderate: 50 pages per category (~40-60 min)")
    print("  - Aggressive: 100 pages per category (~1-2 hours)")

    pages = input("\nEnter pages per category (default 50): ").strip()
    pages_per_category = int(pages) if pages.isdigit() else 50

    print("\nWhat would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_capital_com_categories(pages_per_category)

        if urls:
            print(f"\n{'='*80}")
            print("NEXT STEP")
            print(f"{'='*80}")
            print(f"\nURLs collected: {len(urls)}")
            print(f"Saved to: {filename}")
            print(f"\nTo scrape these URLs, run this script again and choose option 2")

    elif choice == "2":
        import os

        # Find most recent URL file
        url_files = [f for f in os.listdir('.') if f.startswith('capital_com_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound URL files:")
            for i, f in enumerate(url_files[:5], 1):
                print(f"  {i}. {f}")

            choice = input(f"\nUse most recent ({url_files[0]})? (y/n): ").strip()

            if choice.lower() == 'y':
                scrape_capital_com_urls(url_files[0])
            else:
                filename = input("Enter filename: ").strip()
                scrape_capital_com_urls(filename)
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_capital_com_urls(filename)

    elif choice == "3":
        # Complete workflow
        urls, filename = search_capital_com_categories(pages_per_category)

        if urls:
            print(f"\nStep 1 complete: {len(urls)} URLs found")
            print("\nProceed to Step 2: Scraping...")
            scrape_capital_com_urls(filename)


if __name__ == "__main__":
    main()
