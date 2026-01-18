"""
Get all iron ore article URLs from mining.com category page
This is the FASTEST approach - just grab all URLs from the category page
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin


def get_all_iron_ore_urls_from_category():
    """
    Get all article URLs from mining.com's iron ore category
    This is much simpler and faster than crawling!
    """
    print("\n" + "="*80)
    print("FAST URL EXTRACTION - mining.com iron ore category")
    print("="*80)

    base_url = "https://www.mining.com/commodity/iron-ore/"
    all_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    print(f"\nFetching: {base_url}")

    try:
        response = session.get(base_url, timeout=30)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')

        # Find all article links on the page
        # Mining.com typically uses <a> tags with article titles
        for link in soup.find_all('a', href=True):
            url = urljoin(base_url, link['href'])

            # Filter for actual articles (mining.com domain, looks like article)
            if 'mining.com' in url and url not in all_urls:
                # Exclude category pages, tags, etc.
                exclude_patterns = [
                    '/commodity/', '/category/', '/tag/', '/region/',
                    '/jobs', '/ranking', '/advertise', '/contact',
                    '/press-release', '/video/', '/markets/'
                ]

                if not any(pattern in url for pattern in exclude_patterns):
                    # This looks like an article
                    all_urls.append(url)

        print(f"Found {len(all_urls)} potential article URLs")

        # Check if there's pagination
        page = 1
        max_pages = 10  # Limit to prevent infinite loop

        while page < max_pages:
            page += 1
            page_url = f"{base_url}page/{page}/"
            print(f"\nChecking page {page}: {page_url}")

            try:
                response = session.get(page_url, timeout=30)
                if response.status_code == 404:
                    print(f"  Page {page} doesn't exist, stopping pagination")
                    break

                response.raise_for_status()
                soup = BeautifulSoup(response.content, 'html.parser')

                page_urls = []
                for link in soup.find_all('a', href=True):
                    url = urljoin(base_url, link['href'])

                    if 'mining.com' in url and url not in all_urls:
                        exclude_patterns = [
                            '/commodity/', '/category/', '/tag/', '/region/',
                            '/jobs', '/ranking', '/advertise', '/contact',
                            '/press-release', '/video/', '/markets/'
                        ]

                        if not any(pattern in url for pattern in exclude_patterns):
                            all_urls.append(url)
                            page_urls.append(url)

                print(f"  Found {len(page_urls)} more URLs on page {page}")

                if len(page_urls) == 0:
                    print("  No more articles, stopping pagination")
                    break

            except Exception as e:
                print(f"  Error on page {page}: {e}")
                break

        # Remove duplicates
        all_urls = list(set(all_urls))

        print(f"\n{'='*80}")
        print(f"TOTAL URLS FOUND: {len(all_urls)}")
        print(f"{'='*80}")

        # Save to file
        with open('mining_com_all_iron_ore_urls.txt', 'w', encoding='utf-8') as f:
            for url in all_urls:
                f.write(url + '\n')

        print(f"\n✅ Saved {len(all_urls)} URLs to 'mining_com_all_iron_ore_urls.txt'")

        # Show sample
        print("\nSample URLs found:")
        for url in all_urls[:10]:
            print(f"  - {url}")

        if len(all_urls) > 10:
            print(f"  ... and {len(all_urls) - 10} more")

        return all_urls

    except Exception as e:
        print(f"Error: {e}")
        return []


def scrape_found_urls():
    """
    After getting URLs, scrape them for forecast data
    """
    print("\n" + "="*80)
    print("STEP 2: Scraping URLs for forecast data")
    print("="*80)

    # Read URLs from file
    try:
        with open('mining_com_all_iron_ore_urls.txt', 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip()]

        print(f"\nLoaded {len(urls)} URLs from file")

        # Now scrape them
        from iron_ore_scraper import IronOreForecastScraper

        scraper = IronOreForecastScraper()
        scraper.scrape_urls(urls)

        # Export
        scraper.print_summary()
        scraper.export_to_csv('mining_com_iron_ore_forecasts.csv')
        scraper.export_to_json('mining_com_iron_ore_forecasts.json')

        print("\n✅ Complete! Check the CSV/JSON files for results")

    except FileNotFoundError:
        print("Error: Run get_all_iron_ore_urls_from_category() first")


def main():
    """Main workflow"""
    print("\n" + "#"*80)
    print("# MINING.COM IRON ORE - FAST URL EXTRACTION")
    print("#"*80)
    print("\nThis approach:")
    print("  1. Goes directly to the iron ore category page")
    print("  2. Extracts ALL article URLs from that category")
    print("  3. Scrapes each article for forecast data")
    print("\nMuch faster than crawling the entire site!\n")

    # Step 1: Get all URLs
    urls = get_all_iron_ore_urls_from_category()

    if urls:
        # Step 2: Scrape them
        response = input("\nScrape these URLs for forecast data? (y/n): ")
        if response.lower() == 'y':
            scrape_found_urls()
        else:
            print("\nURLs saved to 'mining_com_all_iron_ore_urls.txt'")
            print("Run scrape_found_urls() when ready to scrape them")
    else:
        print("\n❌ No URLs found")


if __name__ == "__main__":
    main()
