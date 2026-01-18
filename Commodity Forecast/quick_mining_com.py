"""
Quick script specifically for mining.com
Goes directly to iron ore category instead of crawling everything
"""

from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper


def scrape_mining_com_iron_ore():
    """
    Smart approach: Go directly to mining.com's iron ore category
    Much faster than crawling the entire site!
    """
    print("\n" + "="*80)
    print("MINING.COM IRON ORE SCRAPER - Smart Approach")
    print("="*80)

    finder = IronOreArticleFinder()

    # Strategy: Target specific iron ore URLs on mining.com
    target_urls = [
        "https://www.mining.com/commodity/iron-ore/",  # Direct iron ore category
        "https://www.mining.com/tag/iron-ore/",         # Iron ore tag page
    ]

    print("\nStep 1: Searching iron ore categories on mining.com...")

    for url in target_urls:
        print(f"\n→ Checking: {url}")
        try:
            finder.search_news_section(url, max_articles=100)
        except Exception as e:
            print(f"  Could not access: {e}")

    print(f"\nStep 2: Found {len(finder.found_articles)} iron ore articles")

    if finder.found_articles:
        # Show what we found
        print("\nArticles discovered:")
        for i, article in enumerate(finder.found_articles[:10], 1):
            print(f"{i}. {article['title'][:70]}")

        if len(finder.found_articles) > 10:
            print(f"... and {len(finder.found_articles) - 10} more")

        # Save URLs
        finder.save_results('mining_com_iron_ore_urls.txt')

        # Now scrape them for forecast data
        print("\nStep 3: Scraping articles for price forecasts...")
        scraper = IronOreForecastScraper()
        scraper.scrape_urls(finder.get_urls_list())

        # Export results
        print("\nStep 4: Exporting results...")
        scraper.print_summary()
        scraper.export_to_csv('mining_com_forecasts.csv')
        scraper.export_to_json('mining_com_forecasts.json')

        print("\n" + "="*80)
        print("✅ COMPLETE!")
        print("="*80)
        print(f"\nFiles created:")
        print(f"  - mining_com_iron_ore_urls.txt ({len(finder.found_articles)} URLs)")
        print(f"  - mining_com_forecasts.csv ({len(scraper.forecasts)} forecasts)")
        print(f"  - mining_com_forecasts.json")

    else:
        print("\n❌ No articles found in iron ore category")
        print("\nTrying alternative: Search for 'iron ore' across the site...")

        # Fallback: broader search
        finder.search_website(
            "https://www.mining.com/commodity/iron-ore/",
            max_pages=50,
            max_depth=2
        )

        if finder.found_articles:
            print(f"\n✅ Found {len(finder.found_articles)} articles via broader search")
            scraper = IronOreForecastScraper()
            scraper.scrape_urls(finder.get_urls_list())
            scraper.export_to_csv('mining_com_forecasts.csv')
        else:
            print("\n⚠ Still no articles found. Mining.com might not have recent iron ore forecast content.")


def main():
    """Main entry point"""
    print("\n" + "#"*80)
    print("# MINING.COM IRON ORE SCRAPER")
    print("#"*80)
    print("\nThis script goes directly to mining.com's iron ore category")
    print("instead of crawling the entire site (much faster!)\n")

    scrape_mining_com_iron_ore()


if __name__ == "__main__":
    main()
