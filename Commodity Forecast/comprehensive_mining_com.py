"""
Comprehensive Mining.com Scraper
Searches multiple categories and sections for iron ore content
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time


def get_urls_from_category(category_url, max_pages=20):
    """
    Get all article URLs from a specific category with pagination

    Args:
        category_url: The category page URL (e.g., https://www.mining.com/commodity/iron-ore/)
        max_pages: Maximum number of pages to check (default 20)
    """
    print(f"\n{'='*80}")
    print(f"Extracting URLs from: {category_url}")
    print(f"{'='*80}")

    all_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    # Page 1
    print(f"\nPage 1: {category_url}")
    try:
        response = session.get(category_url, timeout=30)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')

        page_urls = extract_article_urls(soup, category_url)
        all_urls.extend(page_urls)
        print(f"  Found {len(page_urls)} URLs")

    except Exception as e:
        print(f"  Error: {e}")
        return all_urls

    # Pagination
    for page in range(2, max_pages + 1):
        page_url = f"{category_url}page/{page}/"
        print(f"\nPage {page}: {page_url}")

        try:
            response = session.get(page_url, timeout=30)

            if response.status_code == 404:
                print(f"  Page {page} doesn't exist, stopping")
                break

            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')

            page_urls = extract_article_urls(soup, category_url)

            if len(page_urls) == 0:
                print(f"  No more articles, stopping")
                break

            all_urls.extend(page_urls)
            print(f"  Found {len(page_urls)} URLs")

            time.sleep(1)  # Be polite

        except Exception as e:
            print(f"  Error: {e}")
            break

    # Remove duplicates
    all_urls = list(set(all_urls))
    print(f"\n→ Total unique URLs from this category: {len(all_urls)}")

    return all_urls


def extract_article_urls(soup, base_url):
    """Extract article URLs from a page"""
    urls = []

    for link in soup.find_all('a', href=True):
        url = urljoin(base_url, link['href'])

        # Filter for actual articles
        if 'mining.com' in url and url not in urls:
            # Exclude non-article pages
            exclude_patterns = [
                '/commodity/', '/category/', '/tag/', '/region/',
                '/jobs', '/ranking', '/advertise', '/contact',
                '/press-release', '/markets/', '/about',
                '/privacy', '/terms', '/wp-content', '/wp-admin'
            ]

            if not any(pattern in url for pattern in exclude_patterns):
                # Check if it looks like an article (has hyphens or /web/)
                if '-' in url or '/web/' in url:
                    urls.append(url)

    return urls


def search_multiple_categories():
    """
    Search multiple categories on mining.com for iron ore content
    """
    print("\n" + "#"*80)
    print("# COMPREHENSIVE MINING.COM SCRAPER")
    print("#"*80)
    print("\nSearching multiple categories for iron ore articles...")

    all_urls = []

    # Strategy: Search all relevant categories
    categories = {
        "Iron Ore Commodity": "https://www.mining.com/commodity/iron-ore/",
        "Iron Ore Tag": "https://www.mining.com/tag/iron-ore/",
        "Steel Tag": "https://www.mining.com/tag/steel/",  # Often discusses iron ore
        "China Region": "https://www.mining.com/region/china/",  # Major iron ore market
        "Australia Region": "https://www.mining.com/region/australia/",  # Major producer
        "Brazil Region": "https://www.mining.com/region/brazil/",  # Major producer
    }

    for name, url in categories.items():
        print(f"\n{'='*80}")
        print(f"Category: {name}")
        print(f"{'='*80}")

        urls = get_urls_from_category(url, max_pages=10)

        if urls:
            all_urls.extend(urls)
            print(f"✓ Added {len(urls)} URLs from {name}")
        else:
            print(f"✗ No URLs found in {name}")

        time.sleep(2)  # Be polite between categories

    # Remove duplicates across all categories
    all_urls = list(set(all_urls))

    print(f"\n{'='*80}")
    print(f"SUMMARY")
    print(f"{'='*80}")
    print(f"Total unique article URLs found: {len(all_urls)}")

    # Save to file
    filename = 'mining_com_comprehensive_urls.txt'
    with open(filename, 'w', encoding='utf-8') as f:
        for url in all_urls:
            f.write(url + '\n')

    print(f"\n✅ Saved {len(all_urls)} URLs to '{filename}'")

    # Show sample
    print(f"\nSample URLs (first 10):")
    for i, url in enumerate(all_urls[:10], 1):
        print(f"{i}. {url}")

    if len(all_urls) > 10:
        print(f"... and {len(all_urls) - 10} more")

    return all_urls


def search_by_year(start_year=2013, end_year=2025):
    """
    Search for iron ore articles by year
    Some sites organize content by date
    """
    print("\n" + "="*80)
    print("SEARCHING BY YEAR")
    print("="*80)

    all_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    for year in range(start_year, end_year + 1):
        print(f"\nSearching year: {year}")

        # Try different date-based URL patterns
        date_urls = [
            f"https://www.mining.com/{year}/",
            f"https://www.mining.com/commodity/iron-ore/?year={year}",
        ]

        for url in date_urls:
            try:
                print(f"  Trying: {url}")
                response = session.get(url, timeout=30)

                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    urls = extract_article_urls(soup, url)

                    if urls:
                        print(f"    ✓ Found {len(urls)} URLs")
                        all_urls.extend(urls)
                    else:
                        print(f"    No URLs found")
                else:
                    print(f"    Status: {response.status_code}")

            except Exception as e:
                print(f"    Error: {e}")

        time.sleep(1)

    all_urls = list(set(all_urls))
    print(f"\nTotal URLs found by year: {len(all_urls)}")

    return all_urls


def filter_iron_ore_urls(all_urls):
    """
    Filter URLs to only those likely about iron ore
    (Quick filter based on URL text, before scraping)
    """
    print("\n" + "="*80)
    print("FILTERING FOR IRON ORE CONTENT")
    print("="*80)

    iron_ore_keywords = [
        'iron-ore', 'iron_ore', 'ironore',
        'vale', 'rio-tinto', 'bhp', 'fortescue',  # Major iron ore producers
        'pilbara', 'carajas',  # Major iron ore regions
        'platts', 'cfr-china'
    ]

    filtered_urls = []

    for url in all_urls:
        url_lower = url.lower()
        if any(keyword in url_lower for keyword in iron_ore_keywords):
            filtered_urls.append(url)

    print(f"URLs before filtering: {len(all_urls)}")
    print(f"URLs after filtering: {len(filtered_urls)}")
    print(f"Filtered out: {len(all_urls) - len(filtered_urls)}")

    return filtered_urls


def scrape_all_urls(url_file='mining_com_comprehensive_urls.txt'):
    """
    Scrape all URLs from the file for forecast data
    """
    print("\n" + "="*80)
    print("SCRAPING ALL URLs FOR FORECAST DATA")
    print("="*80)

    try:
        with open(url_file, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip()]

        print(f"\nLoaded {len(urls)} URLs from {url_file}")

        # Optional: Filter for likely iron ore content
        response = input("\nFilter for iron ore keywords in URLs? (y/n): ")
        if response.lower() == 'y':
            urls = filter_iron_ore_urls(urls)

        print(f"\nScraping {len(urls)} URLs for forecast data...")
        print("This may take a while...\n")

        from iron_ore_scraper import IronOreForecastScraper

        scraper = IronOreForecastScraper()
        scraper.scrape_urls(urls)

        # Export results
        scraper.print_summary()
        scraper.export_to_csv('mining_com_comprehensive_forecasts.csv')
        scraper.export_to_json('mining_com_comprehensive_forecasts.json')

        print("\n" + "="*80)
        print("✅ SCRAPING COMPLETE!")
        print("="*80)
        print(f"\nFiles created:")
        print(f"  - mining_com_comprehensive_forecasts.csv ({len(scraper.forecasts)} forecasts)")
        print(f"  - mining_com_comprehensive_forecasts.json")

        if scraper.forecasts:
            print(f"\nForecast data extracted:")
            print(f"  - Total forecasts: {len(scraper.forecasts)}")

            # Show breakdown by year
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

    except FileNotFoundError:
        print(f"Error: {url_file} not found")
        print("Run search_multiple_categories() first to generate the URL file")


def main():
    """Main workflow"""
    print("\n" + "#"*80)
    print("# COMPREHENSIVE MINING.COM SCRAPER")
    print("#"*80)
    print("\nThis script searches multiple categories and sections on mining.com")
    print("to find as many iron ore articles as possible.\n")

    print("What would you like to do?")
    print("1. Search multiple categories (iron ore, steel, regions, etc.)")
    print("2. Search by year (2013-2025)")
    print("3. Both (comprehensive search)")
    print("4. Scrape existing URL file")

    choice = input("\nEnter choice (1-4): ").strip()

    all_urls = []

    if choice == "1":
        all_urls = search_multiple_categories()

    elif choice == "2":
        all_urls = search_by_year(2013, 2025)

        if all_urls:
            filename = 'mining_com_by_year_urls.txt'
            with open(filename, 'w', encoding='utf-8') as f:
                for url in all_urls:
                    f.write(url + '\n')
            print(f"\n✅ Saved {len(all_urls)} URLs to '{filename}'")

    elif choice == "3":
        print("\n→ Step 1: Searching categories...")
        urls1 = search_multiple_categories()

        print("\n→ Step 2: Searching by year...")
        urls2 = search_by_year(2013, 2025)

        all_urls = list(set(urls1 + urls2))

        filename = 'mining_com_all_methods_urls.txt'
        with open(filename, 'w', encoding='utf-8') as f:
            for url in all_urls:
                f.write(url + '\n')

        print(f"\n{'='*80}")
        print("COMBINED RESULTS")
        print(f"{'='*80}")
        print(f"Total unique URLs: {len(all_urls)}")
        print(f"✅ Saved to '{filename}'")

    elif choice == "4":
        scrape_all_urls()
        return

    # Ask if they want to scrape now
    if all_urls:
        response = input(f"\nFound {len(all_urls)} URLs. Scrape them now? (y/n): ")
        if response.lower() == 'y':
            # Save first
            filename = 'mining_com_temp_urls.txt'
            with open(filename, 'w', encoding='utf-8') as f:
                for url in all_urls:
                    f.write(url + '\n')
            scrape_all_urls(filename)


if __name__ == "__main__":
    main()
