"""
Scrape URLs from a text file and create CSV/JSON output
Works with any URL file (mining.com, capital.com, etc.)
"""

from iron_ore_scraper import IronOreForecastScraper
from datetime import datetime


def scrape_urls_from_file(filename):
    """
    Read URLs from a text file and scrape them for forecast data

    Args:
        filename: Path to text file with URLs (one per line)
    """
    print("\n" + "="*80)
    print("SCRAPING URLs FROM FILE")
    print("="*80)
    print(f"\nFile: {filename}")

    try:
        # Read URLs from file
        with open(filename, 'r', encoding='utf-8') as f:
            urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]

        print(f"Loaded {len(urls)} URLs\n")

        # Show the URLs
        print("URLs to scrape:")
        for i, url in enumerate(urls, 1):
            print(f"{i}. {url}")

        # Confirm
        response = input(f"\nScrape these {len(urls)} URLs? (y/n): ").strip().lower()
        if response != 'y':
            print("Cancelled")
            return

        # Create scraper
        scraper = IronOreForecastScraper()

        # Scrape with progress
        print(f"\n{'='*80}")
        print("SCRAPING IN PROGRESS")
        print(f"{'='*80}\n")

        for i, url in enumerate(urls, 1):
            print(f"[{i}/{len(urls)}] Scraping: {url[:70]}...")
            scraper.scrape_url(url)

            # Show progress
            print(f"  → Forecasts found so far: {len(scraper.forecasts)}")

        # Results summary
        print(f"\n{'='*80}")
        print("SCRAPING COMPLETE")
        print(f"{'='*80}")

        scraper.print_summary()

        # Export with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")

        # Determine source from filename
        if 'capital' in filename.lower():
            prefix = 'capital_com'
        elif 'mining' in filename.lower():
            prefix = 'mining_com'
        else:
            prefix = 'scraped'

        csv_file = f'{prefix}_forecasts_{timestamp}.csv'
        json_file = f'{prefix}_forecasts_{timestamp}.json'

        scraper.export_to_csv(csv_file)
        scraper.export_to_json(json_file)

        print(f"\n✅ Files created:")
        print(f"  - {csv_file}")
        print(f"  - {json_file}")

        # Show statistics
        if scraper.forecasts:
            print(f"\nExtracted data:")
            print(f"  Total forecasts: {len(scraper.forecasts)}")

            # Count with prices
            with_prices = sum(1 for f in scraper.forecasts if f.price_usd or f.price_range_min)
            print(f"  With prices: {with_prices}")

            # Count with dates
            with_dates = sum(1 for f in scraper.forecasts if f.outlook_date)
            print(f"  With outlook dates: {with_dates}")

            # Price stats
            prices = [f.price_usd for f in scraper.forecasts if f.price_usd]
            if prices:
                print(f"\n  Price statistics:")
                print(f"    Min: ${min(prices):.2f}")
                print(f"    Max: ${max(prices):.2f}")
                print(f"    Average: ${sum(prices)/len(prices):.2f}")

    except FileNotFoundError:
        print(f"\n✗ Error: File '{filename}' not found")
        print("\nMake sure the file exists in the current directory")
    except Exception as e:
        print(f"\n✗ Error: {e}")


def main():
    """Main function - finds URL files or asks for filename"""
    print("\n" + "#"*80)
    print("# SCRAPE URLs FROM FILE")
    print("#"*80)
    print("\nThis script:")
    print("  1. Reads URLs from a text file")
    print("  2. Scrapes each URL for iron ore forecast data")
    print("  3. Exports results to CSV and JSON\n")

    # Look for URL files in current directory
    import os

    url_files = [f for f in os.listdir('.') if f.endswith('.txt') and
                 any(kw in f.lower() for kw in ['url', 'capital', 'mining', 'iron'])]

    if url_files:
        print("Found URL files:")
        for i, f in enumerate(url_files, 1):
            print(f"  {i}. {f}")

        print(f"\n  0. Enter filename manually")

        choice = input("\nSelect file (number): ").strip()

        if choice.isdigit() and 0 < int(choice) <= len(url_files):
            filename = url_files[int(choice) - 1]
            print(f"\nUsing: {filename}")
            scrape_urls_from_file(filename)
        elif choice == '0':
            filename = input("\nEnter filename: ").strip()
            scrape_urls_from_file(filename)
        else:
            print("Invalid choice")
    else:
        filename = input("\nEnter URL file name: ").strip()
        if filename:
            scrape_urls_from_file(filename)
        else:
            print("No filename provided")


if __name__ == "__main__":
    main()
