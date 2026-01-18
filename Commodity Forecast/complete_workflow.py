"""
Complete Workflow: Find URLs → Scrape Articles → Export Data
This combines the URL finder and scraper for a complete solution
"""

from url_finder import IronOreArticleFinder
from iron_ore_scraper import IronOreForecastScraper
import json


def workflow_example_1():
    """
    Workflow 1: Crawl a website to find articles, then scrape them
    Use this when you have a website but don't know specific article URLs
    """
    print("\n" + "=" * 80)
    print("WORKFLOW 1: Discover articles and scrape them")
    print("=" * 80)

    # Step 1: Find article URLs
    print("\nStep 1: Finding iron ore forecast articles...")
    finder = IronOreArticleFinder()

    # Search a news section (adjust URL and parameters as needed)
    finder.search_website(
        start_url="https://www.mining.com",  # Change this to your target
        max_pages=500,  # How many pages to crawl
        max_depth=5    # How deep to go (2 = homepage + linked pages)
    )

    # Get the URLs we found
    article_urls = finder.get_urls_list()

    if not article_urls:
        print("\nNo articles found. Try:")
        print("  - Different starting URL (e.g., /news/ or /commodities/ section)")
        print("  - Increase max_pages or max_depth")
        print("  - Check if site blocks crawlers")
        return

    # Save found URLs for reference
    finder.save_results('discovered_urls.txt')

    # Step 2: Scrape the found articles
    print("\nStep 2: Scraping found articles for forecast data...")
    scraper = IronOreForecastScraper()
    scraper.scrape_urls(article_urls)

    # Step 3: Export results
    print("\nStep 3: Exporting results...")
    scraper.print_summary()
    scraper.export_to_csv('iron_ore_forecasts_discovered.csv')
    scraper.export_to_json('iron_ore_forecasts_discovered.json')

    print("\n✓ Workflow complete!")


def workflow_example_2():
    """
    Workflow 2: Use specific URLs you already know
    Use this when you have direct URLs to articles
    """
    print("\n" + "=" * 80)
    print("WORKFLOW 2: Scrape specific article URLs")
    print("=" * 80)

    # You provide the specific article URLs
    article_urls = [
        # Add your specific article URLs here:
        # "https://www.reuters.com/markets/commodities/iron-ore-2024-forecast-article",
        # "https://www.mining.com/iron-ore-price-outlook-2024/",
        # "https://www.spglobal.com/commodityinsights/.../iron-ore-forecast",
    ]

    if not article_urls or not article_urls[0]:
        print("Please add specific article URLs to the article_urls list")
        print("\nExample URLs to look for:")
        print("  - https://www.reuters.com/markets/commodities/[article-name]")
        print("  - https://www.mining.com/[article-name]")
        print("  - https://www.spglobal.com/commodityinsights/[article-name]")
        return

    # Scrape the articles
    scraper = IronOreForecastScraper()
    scraper.scrape_urls(article_urls)

    # Export results
    scraper.print_summary()
    scraper.export_to_csv('iron_ore_forecasts_manual.csv')
    scraper.export_to_json('iron_ore_forecasts_manual.json')

    print("\n✓ Workflow complete!")


def workflow_example_3():
    """
    Workflow 3: Search multiple news sections
    Use this for targeted searching of specific site sections
    """
    print("\n" + "=" * 80)
    print("WORKFLOW 3: Search multiple news sections")
    print("=" * 80)

    # Define news section URLs to search
    news_sections = [
        # Example news sections (replace with real ones):
        # "https://www.mining.com/category/commodities/",
        # "https://www.reuters.com/markets/commodities/",
        # "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/",
    ]

    if not news_sections or not news_sections[0]:
        print("Please add news section URLs to search")
        print("\nTips for finding news sections:")
        print("  - Look for /news/, /commodities/, /metals/ pages")
        print("  - Use site navigation menus")
        print("  - Check for article archive pages")
        return

    # Find articles across multiple sections
    finder = IronOreArticleFinder()

    for news_url in news_sections:
        print(f"\n--- Searching: {news_url} ---")
        finder.search_news_section(news_url, max_articles=30)

    # Save discovered URLs
    finder.save_results('discovered_from_sections.txt')

    # Scrape found articles
    if finder.found_articles:
        article_urls = finder.get_urls_list()
        print(f"\nScraping {len(article_urls)} articles...")

        scraper = IronOreForecastScraper()
        scraper.scrape_urls(article_urls)

        # Export
        scraper.print_summary()
        scraper.export_to_csv('forecasts_from_sections.csv')
        scraper.export_to_json('forecasts_from_sections.json')

        print("\n✓ Workflow complete!")
    else:
        print("\nNo articles found in the specified sections")


def interactive_workflow():
    """
    Interactive workflow - asks user what they want to do
    """
    print("\n" + "=" * 80)
    print("Iron Ore Forecast Scraper - Interactive Workflow")
    print("=" * 80)

    print("\nWhat would you like to do?")
    print("1. I have specific article URLs to scrape")
    print("2. I want to discover articles from a website")
    print("3. I want to search specific news sections")
    print("4. Show me example URLs to get started")

    choice = input("\nEnter your choice (1-4): ").strip()

    if choice == "1":
        print("\nEnter article URLs (one per line, empty line to finish):")
        urls = []
        while True:
            url = input().strip()
            if not url:
                break
            urls.append(url)

        if urls:
            scraper = IronOreForecastScraper()
            scraper.scrape_urls(urls)
            scraper.print_summary()
            scraper.export_to_csv('scraped_forecasts.csv')
        else:
            print("No URLs provided")

    elif choice == "2":
        url = input("\nEnter starting URL (e.g., https://www.mining.com/): ").strip()
        max_pages = input("Max pages to crawl (default 20): ").strip() or "20"

        finder = IronOreArticleFinder()
        finder.search_website(url, max_pages=int(max_pages), max_depth=2)

        if finder.found_articles:
            scraper = IronOreForecastScraper()
            scraper.scrape_urls(finder.get_urls_list())
            scraper.print_summary()
            scraper.export_to_csv('discovered_forecasts.csv')

    elif choice == "3":
        print("\nEnter news section URLs (one per line, empty line to finish):")
        sections = []
        while True:
            url = input().strip()
            if not url:
                break
            sections.append(url)

        if sections:
            finder = IronOreArticleFinder()
            for section in sections:
                finder.search_news_section(section, max_articles=30)

            if finder.found_articles:
                scraper = IronOreForecastScraper()
                scraper.scrape_urls(finder.get_urls_list())
                scraper.print_summary()
                scraper.export_to_csv('section_forecasts.csv')

    elif choice == "4":
        print("\n" + "=" * 80)
        print("Example URLs and How to Use Them")
        print("=" * 80)

        print("\n1. NEWS SECTION URLs (use with search_news_section):")
        print("   - https://www.mining.com/category/commodities/")
        print("   - https://www.reuters.com/markets/commodities/")
        print("   - https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/metals/")

        print("\n2. SPECIFIC ARTICLE URLs (use directly with scraper):")
        print("   - https://www.reuters.com/markets/commodities/iron-ore-2024-forecast-12345/")
        print("   - https://www.mining.com/iron-ore-price-outlook-2024/")

        print("\n3. STARTING URLs for crawling (use with search_website):")
        print("   - https://www.mining.com/")
        print("   - https://www.fastmarkets.com/insights/")

        print("\nHow to find these:")
        print("  → Go to the website in your browser")
        print("  → Navigate to 'News', 'Commodities', or 'Metals' section")
        print("  → Copy the URL of that section or specific articles")


def main():
    """Main entry point"""
    print("\n" + "#" * 80)
    print("# Iron Ore Forecast Scraper - Complete Workflow")
    print("#" * 80)

    print("\nThis script provides different workflows:")
    print("  - Workflow 1: Automatically discover and scrape articles")
    print("  - Workflow 2: Scrape specific URLs you provide")
    print("  - Workflow 3: Search multiple news sections")
    print("  - Interactive: Choose what you want to do")

    print("\n" + "-" * 80)
    print("IMPORTANT: How URLs Work")
    print("-" * 80)
    print("\n❌ DON'T just provide 'https://www.mining.com'")
    print("   → This only scrapes the homepage")
    print("\n✓ DO provide:")
    print("   → Specific article URLs: 'https://www.mining.com/article-name'")
    print("   → News section URLs: 'https://www.mining.com/news/'")
    print("   → Use url_finder to discover articles automatically")

    print("\n" + "=" * 80)
    print("\nUncomment one of the workflow examples below to run:")
    print("  - workflow_example_1()  # Auto-discover articles")
    print("  - workflow_example_2()  # Use specific URLs")
    print("  - workflow_example_3()  # Search news sections")
    print("  - interactive_workflow()  # Interactive mode")


if __name__ == "__main__":
    main()

    # Uncomment the workflow you want to use:
    workflow_example_1()
    # workflow_example_2()
    # workflow_example_3()
    # interactive_workflow()
