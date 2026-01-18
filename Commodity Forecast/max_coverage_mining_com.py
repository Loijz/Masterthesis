"""
MAXIMUM COVERAGE Mining.com Scraper
Searches extensively - designed to run for extended periods
Adjust max_pages based on how long you want to run
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time
from datetime import datetime


def get_urls_from_category(category_url, max_pages=50):
    """
    Get all article URLs from a specific category with pagination

    Args:
        category_url: The category page URL
        max_pages: Maximum number of pages to check (default 50, can go much higher)
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
        if page == 1:
            page_url = category_url
        else:
            page_url = f"{category_url}page/{page}/"

        print(f"  Page {page}/{max_pages}: ", end='', flush=True)

        try:
            response = session.get(page_url, timeout=30)

            if response.status_code == 404:
                print(f"doesn't exist, stopping")
                break

            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract article URLs
            page_urls = []
            for link in soup.find_all('a', href=True):
                url = urljoin(category_url, link['href'])

                if 'mining.com' in url and url not in all_urls:
                    # Exclude non-article pages
                    exclude_patterns = [
                        '/commodity/', '/category/', '/tag/', '/region/',
                        '/jobs', '/ranking', '/advertise', '/contact',
                        '/press-release', '/markets/', '/about',
                        '/privacy', '/terms', '/wp-content', '/wp-admin',
                        '/video/'  # Skip videos unless you want them
                    ]

                    if not any(pattern in url for pattern in exclude_patterns):
                        # Check if it looks like an article
                        if '-' in url or '/web/' in url:
                            page_urls.append(url)
                            all_urls.append(url)

            if len(page_urls) > 0:
                print(f"found {len(page_urls)} URLs (total: {len(all_urls)})")
            else:
                print(f"no articles found, stopping")
                break

            time.sleep(1)  # Be polite - 1 second delay between pages

        except Exception as e:
            print(f"error: {e}")
            break

    print(f"\n→ Total unique URLs from this category: {len(all_urls)}")
    return all_urls


def search_maximum_categories(pages_per_category=50):
    """
    Search ALL relevant categories extensively

    Args:
        pages_per_category: How many pages to check in each category
                          Default 50, can increase to 100+ for maximum coverage
    """
    print("\n" + "#"*80)
    print("# MAXIMUM COVERAGE MINING.COM SCRAPER")
    print("#"*80)
    print(f"\nConfiguration:")
    print(f"  - Pages per category: {pages_per_category}")
    print(f"  - Delay between pages: 1 second")
    print(f"  - Delay between categories: 2 seconds")

    # Calculate estimated time
    num_categories = 13  # See below
    estimated_time_seconds = num_categories * pages_per_category * 1.5  # Average
    estimated_minutes = estimated_time_seconds / 60

    print(f"\nEstimated time: {estimated_minutes:.0f} minutes ({estimated_time_seconds/60/60:.1f} hours)")
    print(f"Note: Will stop early if pages run out\n")

    response = input("Continue? (y/n): ")
    if response.lower() != 'y':
        print("Cancelled")
        return []

    start_time = datetime.now()
    all_urls = []

    # COMPREHENSIVE category list - all relevant sections
    categories = {
        # Direct iron ore categories
        "1. Iron Ore Commodity": "https://www.mining.com/commodity/iron-ore/",
        "2. Iron Ore Tag": "https://www.mining.com/tag/iron-ore/",

        # Related commodities
        "3. Steel Tag": "https://www.mining.com/tag/steel/",

        # Key regions (major producers and consumers)
        "4. China Region": "https://www.mining.com/region/china/",
        "5. Australia Region": "https://www.mining.com/region/australia/",
        "6. Brazil Region": "https://www.mining.com/region/brazil/",
        "7. India Region": "https://www.mining.com/region/india/",

        # Major iron ore companies
        "8. Vale Tag": "https://www.mining.com/tag/vale/",
        "9. Rio Tinto Tag": "https://www.mining.com/tag/rio-tinto/",
        "10. BHP Tag": "https://www.mining.com/tag/bhp/",
        "11. Fortescue Tag": "https://www.mining.com/tag/fortescue-metals-group/",
        "12. Anglo American Tag": "https://www.mining.com/tag/anglo-american/",

        # General mining news (might have iron ore content)
        "13. Base Metals": "https://www.mining.com/category/base-metals/",
    }

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
    print(f"Total time: {elapsed/60:.1f} minutes ({elapsed/3600:.2f} hours)")
    print(f"Categories searched: {len(categories)}")
    print(f"Total unique URLs found: {len(all_urls)}")
    print(f"Average URLs per category: {len(all_urls)/len(categories):.0f}")

    # Save to file
    filename = f'mining_com_maximum_coverage_urls_{datetime.now().strftime("%Y%m%d_%H%M")}.txt'
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# Mining.com Maximum Coverage URL Collection\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total URLs: {len(all_urls)}\n")
        f.write(f"# Pages per category: {pages_per_category}\n")
        f.write(f"# Categories: {len(categories)}\n")
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


def scrape_all_urls(url_file):
    """
    Scrape all URLs from the file for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING ALL URLs FOR FORECAST DATA")
    print("="*80)

    try:
        with open(url_file, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

        print(f"\nLoaded {len(urls)} URLs from {url_file}")

        # Estimate scraping time
        estimated_time = len(urls) * 1.5  # ~1.5 seconds per URL on average
        print(f"Estimated scraping time: {estimated_time/60:.0f} minutes ({estimated_time/3600:.1f} hours)")

        response = input("\nProceed with scraping? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled")
            return

        print(f"\nScraping {len(urls)} URLs for forecast data...")
        print("This will take a while...\n")

        from iron_ore_scraper import IronOreForecastScraper

        start_time = datetime.now()

        scraper = IronOreForecastScraper()
        scraper.scrape_urls(urls)

        elapsed = (datetime.now() - start_time).total_seconds()

        # Export results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        csv_file = f'mining_com_maximum_forecasts_{timestamp}.csv'
        json_file = f'mining_com_maximum_forecasts_{timestamp}.json'

        scraper.print_summary()
        scraper.export_to_csv(csv_file)
        scraper.export_to_json(json_file)

        print("\n" + "="*80)
        print("✅ SCRAPING COMPLETE!")
        print("="*80)
        print(f"Scraping time: {elapsed/60:.1f} minutes ({elapsed/3600:.2f} hours)")
        print(f"\nFiles created:")
        print(f"  - {csv_file} ({len(scraper.forecasts)} forecasts)")
        print(f"  - {json_file}")

        if scraper.forecasts:
            print(f"\nForecast Statistics:")
            print(f"  Total forecasts extracted: {len(scraper.forecasts)}")

            # Count by source
            sources = {}
            for f in scraper.forecasts:
                sources[f.source_name] = sources.get(f.source_name, 0) + 1

            print(f"  Unique sources: {len(sources)}")

            # Count forecasts with outlook dates
            with_dates = sum(1 for f in scraper.forecasts if f.outlook_date)
            print(f"  Forecasts with outlook dates: {with_dates}")

            # Breakdown by year
            years = {}
            for f in scraper.forecasts:
                if f.outlook_date:
                    import re
                    year_match = re.search(r'20\d{2}', str(f.outlook_date))
                    if year_match:
                        year = year_match.group(0)
                        years[year] = years.get(year, 0) + 1

            if years:
                print(f"\n  Forecasts by outlook year:")
                for year in sorted(years.keys()):
                    print(f"    {year}: {years[year]} forecasts")

            # Price statistics
            prices = [f.price_usd for f in scraper.forecasts if f.price_usd]
            if prices:
                print(f"\n  Price statistics:")
                print(f"    Forecasts with prices: {len(prices)}")
                print(f"    Price range: ${min(prices):.2f} - ${max(prices):.2f}")
                print(f"    Average price: ${sum(prices)/len(prices):.2f}")

    except FileNotFoundError:
        print(f"Error: {url_file} not found")
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Main workflow"""
    print("\n" + "#"*80)
    print("# MAXIMUM COVERAGE MINING.COM SCRAPER")
    print("#"*80)
    print("\nThis script performs an EXTENSIVE search of mining.com")
    print("to find as many iron ore articles as possible.\n")

    print("Configuration options:")
    print("  - Conservative: 20 pages per category (~30 min)")
    print("  - Moderate: 50 pages per category (~1-2 hours)")
    print("  - Aggressive: 100 pages per category (~2-4 hours)")
    print("  - Maximum: 200 pages per category (~4-8 hours)")

    pages = input("\nEnter pages per category (default 50): ").strip()
    pages_per_category = int(pages) if pages.isdigit() else 50

    print("\nWhat would you like to do?")
    print("1. Search for URLs (Step 1)")
    print("2. Scrape existing URL file (Step 2)")
    print("3. Both (complete workflow)")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        urls, filename = search_maximum_categories(pages_per_category)

        if urls:
            print(f"\n{'='*80}")
            print("NEXT STEP")
            print(f"{'='*80}")
            print(f"\nURLs collected: {len(urls)}")
            print(f"Saved to: {filename}")
            print(f"\nTo scrape these URLs later, run this script again and choose option 2")
            print(f"Or run: python max_coverage_mining_com.py")

    elif choice == "2":
        import os

        # Find most recent URL file
        url_files = [f for f in os.listdir('.') if f.startswith('mining_com_maximum_coverage_urls_')]

        if url_files:
            url_files.sort(reverse=True)
            print(f"\nFound URL files:")
            for i, f in enumerate(url_files[:5], 1):
                print(f"  {i}. {f}")

            choice = input(f"\nUse most recent ({url_files[0]})? (y/n): ").strip()

            if choice.lower() == 'y':
                scrape_all_urls(url_files[0])
            else:
                filename = input("Enter filename: ").strip()
                scrape_all_urls(filename)
        else:
            filename = input("Enter URL file name: ").strip()
            scrape_all_urls(filename)

    elif choice == "3":
        # Complete workflow
        urls, filename = search_maximum_categories(pages_per_category)

        if urls:
            print(f"\nStep 1 complete: {len(urls)} URLs found")
            print("\nProceed to Step 2: Scraping...")
            scrape_all_urls(filename)


if __name__ == "__main__":
    main()
