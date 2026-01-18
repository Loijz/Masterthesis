"""
Expand your search to find MORE iron ore articles
Builds on what you already have
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import time


def quick_category_search(category_urls, max_pages_per_category=15):
    """
    Quick search of multiple categories

    Args:
        category_urls: List of category URLs to search
        max_pages_per_category: How many pages to check in each category
    """
    print("\n" + "="*80)
    print("EXPANDING SEARCH - Multiple Categories")
    print("="*80)

    all_urls = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    })

    for category_url in category_urls:
        print(f"\n→ Searching: {category_url}")

        category_urls_found = []

        # Search through pages
        for page in range(1, max_pages_per_category + 1):
            if page == 1:
                page_url = category_url
            else:
                page_url = f"{category_url}page/{page}/"

            try:
                response = session.get(page_url, timeout=30)

                if response.status_code == 404:
                    print(f"  Page {page}: No more pages")
                    break

                response.raise_for_status()
                soup = BeautifulSoup(response.content, 'html.parser')

                # Extract article URLs
                page_urls = []
                for link in soup.find_all('a', href=True):
                    url = urljoin(category_url, link['href'])

                    if 'mining.com' in url and url not in all_urls:
                        # Exclude non-article pages
                        exclude = ['/commodity/', '/category/', '/tag/', '/region/',
                                 '/jobs', '/ranking', '/advertise', '/contact',
                                 '/press-release', '/markets/', '/video/']

                        if not any(ex in url for ex in exclude):
                            if '-' in url or '/web/' in url:
                                page_urls.append(url)
                                all_urls.append(url)

                if page_urls:
                    category_urls_found.extend(page_urls)
                    print(f"  Page {page}: Found {len(page_urls)} URLs")
                else:
                    print(f"  Page {page}: No articles found, stopping")
                    break

                time.sleep(0.5)

            except Exception as e:
                print(f"  Page {page}: Error - {e}")
                break

        print(f"  ✓ Total from this category: {len(category_urls_found)}")
        time.sleep(1)

    # Remove duplicates
    all_urls = list(set(all_urls))

    print(f"\n{'='*80}")
    print(f"TOTAL UNIQUE URLs FOUND: {len(all_urls)}")
    print(f"{'='*80}")

    return all_urls


def main():
    """Main function to expand your search"""
    print("\n" + "#"*80)
    print("# EXPAND YOUR SEARCH - Find More Articles")
    print("#"*80)

    print("\nThis will search additional categories on mining.com")
    print("to find more iron ore-related articles.\n")

    # Define categories to search
    categories = {
        "1. Iron Ore Commodity": "https://www.mining.com/commodity/iron-ore/",
        "2. Iron Ore Tag": "https://www.mining.com/tag/iron-ore/",
        "3. Steel Tag": "https://www.mining.com/tag/steel/",
        "4. China Region": "https://www.mining.com/region/china/",
        "5. Australia Region": "https://www.mining.com/region/australia/",
        "6. Brazil Region": "https://www.mining.com/region/brazil/",
        "7. Vale Tag": "https://www.mining.com/tag/vale/",
        "8. Rio Tinto Tag": "https://www.mining.com/tag/rio-tinto/",
        "9. BHP Tag": "https://www.mining.com/tag/bhp/",
        "10. Fortescue Tag": "https://www.mining.com/tag/fortescue-metals-group/",
    }

    print("Available categories to search:")
    for name, url in categories.items():
        print(f"  {name}")

    print("\nOptions:")
    print("  a - Search ALL categories (recommended)")
    print("  s - Select specific categories")

    choice = input("\nYour choice (a/s): ").strip().lower()

    selected_urls = []

    if choice == 'a':
        selected_urls = list(categories.values())
        print(f"\n→ Searching all {len(selected_urls)} categories")

    elif choice == 's':
        print("\nEnter category numbers separated by commas (e.g., 1,2,4)")
        numbers = input("Categories: ").strip()

        for num in numbers.split(','):
            try:
                idx = int(num.strip()) - 1
                category_list = list(categories.items())
                if 0 <= idx < len(category_list):
                    selected_urls.append(category_list[idx][1])
            except:
                pass

        print(f"\n→ Searching {len(selected_urls)} selected categories")

    if not selected_urls:
        print("No categories selected")
        return

    # Ask about pagination depth
    pages = input("\nHow many pages per category? (default 15, more = slower): ").strip()
    max_pages = int(pages) if pages.isdigit() else 15

    # Search!
    print(f"\nStarting search...")
    print(f"Categories: {len(selected_urls)}")
    print(f"Pages per category: {max_pages}")
    print(f"Estimated time: {len(selected_urls) * max_pages * 2} seconds\n")

    all_urls = quick_category_search(selected_urls, max_pages)

    if all_urls:
        # Save to file
        filename = 'mining_com_expanded_urls.txt'
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

        # Ask if they want to scrape
        scrape = input("\nScrape these URLs for forecast data now? (y/n): ").strip().lower()

        if scrape == 'y':
            from iron_ore_scraper import IronOreForecastScraper

            print("\nScraping articles for forecast data...")
            scraper = IronOreForecastScraper()
            scraper.scrape_urls(all_urls)

            # Export
            scraper.print_summary()
            scraper.export_to_csv('mining_com_expanded_forecasts.csv')
            scraper.export_to_json('mining_com_expanded_forecasts.json')

            print("\n✅ Complete!")
        else:
            print(f"\nURLs saved to '{filename}'")
            print("You can scrape them later with:")
            print("  from iron_ore_scraper import IronOreForecastScraper")
            print("  scraper = IronOreForecastScraper()")
            print(f"  with open('{filename}') as f:")
            print("    urls = [line.strip() for line in f]")
            print("  scraper.scrape_urls(urls)")

    else:
        print("\n❌ No URLs found")


if __name__ == "__main__":
    main()
