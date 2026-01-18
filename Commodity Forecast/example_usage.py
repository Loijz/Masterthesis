"""
Example usage script for the Iron Ore Forecast Scraper
Demonstrates how to use the scraper with real-world scenarios
"""

from iron_ore_scraper import IronOreForecastScraper
from config_urls import TARGET_URLS
import json


def basic_example():
    """Basic scraping example"""
    print("=" * 60)
    print("BASIC EXAMPLE: Scraping specific URLs")
    print("=" * 60)

    scraper = IronOreForecastScraper()

    # Example URLs (replace with actual article URLs)
    urls = [
        # Add actual URLs to iron ore forecast articles here
        # "https://www.reuters.com/markets/commodities/iron-ore-article",
        # "https://www.mining.com/iron-ore-forecast-article",
    ]

    if urls and urls[0]:  # Check if URLs are actually provided
        scraper.scrape_urls(urls)
        scraper.print_summary()
        scraper.export_to_csv('example_output.csv')
    else:
        print("Please add actual URLs to the urls list in this example")


def advanced_filtering_example():
    """Example showing how to filter and analyze results"""
    print("\n" + "=" * 60)
    print("ADVANCED EXAMPLE: Filtering and analyzing results")
    print("=" * 60)

    scraper = IronOreForecastScraper()

    # Load example URLs from config
    if TARGET_URLS:
        scraper.scrape_urls(TARGET_URLS)

        if scraper.forecasts:
            # Filter forecasts by criteria
            print("\n--- Filtering Results ---")

            # 1. Forecasts with outlook dates in 2024
            forecasts_2024 = [
                f for f in scraper.forecasts
                if f.outlook_date and '2024' in str(f.outlook_date)
            ]
            print(f"Forecasts for 2024: {len(forecasts_2024)}")

            # 2. High price forecasts (>$100/tonne)
            high_price_forecasts = [
                f for f in scraper.forecasts
                if f.price_usd and f.price_usd > 100
            ]
            print(f"High price forecasts (>$100): {len(high_price_forecasts)}")

            # 3. Forecasts with price ranges
            range_forecasts = [
                f for f in scraper.forecasts
                if f.price_range_min and f.price_range_max
            ]
            print(f"Forecasts with price ranges: {len(range_forecasts)}")

            # 4. Calculate average forecast price
            prices = [f.price_usd for f in scraper.forecasts if f.price_usd]
            if prices:
                avg_price = sum(prices) / len(prices)
                print(f"\nAverage forecast price: ${avg_price:.2f}/tonne")
                print(f"Price range: ${min(prices):.2f} - ${max(prices):.2f}")

            # 5. Group by source
            sources = {}
            for f in scraper.forecasts:
                if f.source_name not in sources:
                    sources[f.source_name] = 0
                sources[f.source_name] += 1

            print("\n--- Forecasts by Source ---")
            for source, count in sources.items():
                print(f"{source}: {count} forecasts")

            # Export filtered results
            scraper.export_to_csv('filtered_forecasts.csv')
        else:
            print("No forecasts found. Check your URLs.")
    else:
        print("Please add URLs to config_urls.py")


def custom_analysis_example():
    """Example showing custom analysis of scraped data"""
    print("\n" + "=" * 60)
    print("CUSTOM ANALYSIS EXAMPLE")
    print("=" * 60)

    scraper = IronOreForecastScraper()

    # Simulate having some data (in practice, you'd scrape first)
    # scraper.scrape_urls(your_urls)

    # Create custom analysis functions
    def analyze_by_year(forecasts):
        """Group forecasts by outlook year"""
        by_year = {}
        for f in forecasts:
            if f.outlook_date:
                # Extract year from outlook date
                import re
                year_match = re.search(r'20\d{2}', str(f.outlook_date))
                if year_match:
                    year = year_match.group(0)
                    if year not in by_year:
                        by_year[year] = []
                    by_year[year].append(f)
        return by_year

    def analyze_by_quarter(forecasts):
        """Group forecasts by quarter"""
        by_quarter = {}
        for f in forecasts:
            if f.outlook_date and 'Q' in str(f.outlook_date):
                quarter = f.outlook_date
                if quarter not in by_quarter:
                    by_quarter[quarter] = []
                by_quarter[quarter].append(f)
        return by_quarter

    if scraper.forecasts:
        # Analyze by year
        by_year = analyze_by_year(scraper.forecasts)
        print("\n--- Forecasts by Year ---")
        for year in sorted(by_year.keys()):
            prices = [f.price_usd for f in by_year[year] if f.price_usd]
            if prices:
                avg = sum(prices) / len(prices)
                print(f"{year}: {len(by_year[year])} forecasts, avg ${avg:.2f}")

        # Analyze by quarter
        by_quarter = analyze_by_quarter(scraper.forecasts)
        if by_quarter:
            print("\n--- Forecasts by Quarter ---")
            for quarter in sorted(by_quarter.keys()):
                print(f"{quarter}: {len(by_quarter[quarter])} forecasts")


def export_example():
    """Example showing different export options"""
    print("\n" + "=" * 60)
    print("EXPORT EXAMPLE")
    print("=" * 60)

    scraper = IronOreForecastScraper()

    # After scraping...
    # scraper.scrape_urls(your_urls)

    if scraper.forecasts:
        # Export to CSV
        scraper.export_to_csv('iron_ore_forecasts_2013_2025.csv')

        # Export to JSON
        scraper.export_to_json('iron_ore_forecasts_2013_2025.json')

        # Custom export: Only high-confidence forecasts
        high_confidence = [
            f for f in scraper.forecasts
            if f.forecast_date and f.outlook_date and f.price_usd
        ]

        if high_confidence:
            with open('high_confidence_forecasts.json', 'w') as file:
                json.dump([f.to_dict() for f in high_confidence], file, indent=2)
            print(f"Exported {len(high_confidence)} high-confidence forecasts")

        # Create a summary report
        with open('scraping_report.txt', 'w') as file:
            file.write("Iron Ore Forecast Scraping Report\n")
            file.write("=" * 50 + "\n\n")
            file.write(f"Total forecasts: {len(scraper.forecasts)}\n")
            file.write(f"High confidence: {len(high_confidence)}\n\n")

            sources = set(f.source_name for f in scraper.forecasts)
            file.write(f"Sources ({len(sources)}):\n")
            for source in sorted(sources):
                count = sum(1 for f in scraper.forecasts if f.source_name == source)
                file.write(f"  - {source}: {count} forecasts\n")

        print("Created scraping_report.txt")


def main():
    """Run all examples"""
    print("\n" + "#" * 60)
    print("# Iron Ore Forecast Scraper - Examples")
    print("#" * 60)

    # Run examples
    basic_example()
    # advanced_filtering_example()
    # custom_analysis_example()
    # export_example()

    print("\n" + "#" * 60)
    print("# Examples completed!")
    print("#" * 60)
    print("\nTo use this scraper:")
    print("1. Add article URLs to config_urls.py")
    print("2. Run: python iron_ore_scraper.py")
    print("3. Check output CSV/JSON files")
    print("\nFor programmatic use, see the examples above.")


if __name__ == "__main__":
    main()
