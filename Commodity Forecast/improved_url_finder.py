"""
Improved URL Finder with more flexible search strategies
"""

from url_finder import IronOreArticleFinder
from typing import List


class ImprovedIronOreFinder(IronOreArticleFinder):
    """Improved finder with relaxed matching and better strategies"""

    def __init__(self, strict_mode=False):
        """
        Args:
            strict_mode: If True, requires URL pattern match. If False, only needs keywords.
        """
        super().__init__()
        self.strict_mode = strict_mode

    def contains_iron_ore_keywords(self, text: str, url: str) -> bool:
        """More flexible keyword matching"""
        text_lower = text.lower()
        url_lower = url.lower()

        # Must contain "iron ore" or "iron-ore"
        iron_ore_found = any(keyword in text_lower or keyword in url_lower
                            for keyword in ['iron ore', 'iron-ore', 'ironore', 'iron_ore'])

        if not iron_ore_found:
            return False

        # Check for forecast/price keywords (more relaxed)
        forecast_keywords = [
            'forecast', 'outlook', 'prediction', 'expect',
            'plummeted', 'raise', 'fall', 'increasing',
            'long-term', 'short-term', 'price', 'prices',
            'market', 'analysis', 'trend', '2024', '2025',
            'quarterly', 'annual', 'projection'
        ]

        forecast_found = any(keyword in text_lower or keyword in url_lower
                           for keyword in forecast_keywords)

        return iron_ore_found and forecast_found

    def search_website_flexible(self, start_url: str, max_pages: int = 50, max_depth: int = 2):
        """
        More flexible search - accepts pages with keywords even without article URL pattern
        """
        print(f"\nFlexible search: {start_url}")
        print(f"Max pages: {max_pages}, Max depth: {max_depth}")
        print(f"Strict mode (requires article URL pattern): {self.strict_mode}\n")

        to_visit = [(start_url, 0)]
        pages_crawled = 0

        while to_visit and pages_crawled < max_pages:
            current_url, depth = to_visit.pop(0)

            if current_url in self.visited_urls or depth > max_depth:
                continue

            self.visited_urls.add(current_url)
            pages_crawled += 1

            print(f"[{pages_crawled}/{max_pages}] Depth {depth}: {current_url[:80]}...")

            soup = self.fetch_page(current_url)
            if not soup:
                continue

            # Get page info
            page_text = soup.get_text(separator=' ', strip=True)[:2000]  # More text
            title = soup.find('title')
            title_text = title.get_text() if title else ""

            is_article = self.is_article_url(current_url)
            has_keywords = self.contains_iron_ore_keywords(page_text + title_text, current_url)

            # In flexible mode, accept if has keywords (even without article URL pattern)
            # In strict mode, require both
            should_include = has_keywords if not self.strict_mode else (is_article and has_keywords)

            if should_include:
                article_info = {
                    'url': current_url,
                    'title': title_text.strip(),
                    'found_at_depth': depth,
                    'is_article_url': is_article
                }
                self.found_articles.append(article_info)
                print(f"  ✓ Found: {title_text[:60]}...")

            # Extract and queue more links
            if depth < max_depth:
                links = self.extract_links(soup, current_url)

                # In flexible mode, prioritize any link
                # In strict mode, prioritize article-looking URLs
                if self.strict_mode:
                    article_links = [l for l in links if self.is_article_url(l)]
                    other_links = [l for l in links if not self.is_article_url(l)]
                    sorted_links = article_links + other_links
                else:
                    sorted_links = links

                for link in sorted_links:
                    if link not in self.visited_urls:
                        to_visit.append((link, depth + 1))

            import time
            time.sleep(0.5)  # Be polite

        print(f"\nSearch complete! Found {len(self.found_articles)} pages")
        return self.found_articles

    def search_by_sitemap(self, sitemap_url: str):
        """
        Try to find articles via sitemap (if available)
        Common sitemap URLs: /sitemap.xml, /sitemap_index.xml
        """
        print(f"\nSearching sitemap: {sitemap_url}")

        soup = self.fetch_page(sitemap_url)
        if not soup:
            print("  Could not fetch sitemap")
            return []

        # Extract URLs from sitemap
        urls = []
        for loc in soup.find_all('loc'):
            url = loc.get_text()
            urls.append(url)

        print(f"  Found {len(urls)} URLs in sitemap")

        # Filter for iron ore articles
        for url in urls[:100]:  # Limit to prevent too many requests
            if url in self.visited_urls:
                continue

            self.visited_urls.add(url)

            # Check URL first
            if 'iron' in url.lower():
                soup = self.fetch_page(url)
                if soup:
                    page_text = soup.get_text(separator=' ', strip=True)[:1000]
                    title = soup.find('title')
                    title_text = title.get_text() if title else ""

                    if self.contains_iron_ore_keywords(page_text + title_text, url):
                        article_info = {
                            'url': url,
                            'title': title_text.strip(),
                            'found_at_depth': 0
                        }
                        self.found_articles.append(article_info)
                        print(f"  ✓ Found: {title_text[:60]}")

        print(f"Found {len(self.found_articles)} articles from sitemap")
        return self.found_articles


def try_multiple_strategies(base_url: str):
    """
    Try multiple strategies to find articles
    """
    print("\n" + "="*80)
    print("TRYING MULTIPLE SEARCH STRATEGIES")
    print("="*80)

    all_articles = []

    # Strategy 1: Flexible search from homepage
    print("\n--- Strategy 1: Flexible search from homepage ---")
    finder1 = ImprovedIronOreFinder(strict_mode=False)
    finder1.search_website_flexible(base_url, max_pages=30, max_depth=2)
    all_articles.extend(finder1.found_articles)

    # Strategy 2: Try common news sections
    print("\n--- Strategy 2: Search common news sections ---")
    common_sections = [
        f"{base_url}/news/",
        f"{base_url}/category/news/",
        f"{base_url}/category/commodities/",
        f"{base_url}/category/metals/",
        f"{base_url}/commodities/",
        f"{base_url}/metals/",
    ]

    finder2 = ImprovedIronOreFinder(strict_mode=False)
    for section in common_sections:
        print(f"\nTrying: {section}")
        try:
            finder2.search_news_section(section, max_articles=20)
        except:
            print(f"  Could not access {section}")

    all_articles.extend(finder2.found_articles)

    # Strategy 3: Try sitemap
    print("\n--- Strategy 3: Try sitemap ---")
    finder3 = ImprovedIronOreFinder()
    try:
        finder3.search_by_sitemap(f"{base_url}/sitemap.xml")
        all_articles.extend(finder3.found_articles)
    except:
        print("  No sitemap found or error accessing it")

    # Remove duplicates
    unique_articles = []
    seen_urls = set()
    for article in all_articles:
        if article['url'] not in seen_urls:
            seen_urls.add(article['url'])
            unique_articles.append(article)

    print("\n" + "="*80)
    print(f"TOTAL UNIQUE ARTICLES FOUND: {len(unique_articles)}")
    print("="*80)

    if unique_articles:
        print("\nArticles found:")
        for i, article in enumerate(unique_articles[:10], 1):
            print(f"{i}. {article['title'][:70]}")
            print(f"   {article['url']}")

        # Save results
        with open('found_articles_all_strategies.txt', 'w', encoding='utf-8') as f:
            for article in unique_articles:
                f.write(f"{article['url']}\n")

        print(f"\n✅ Saved {len(unique_articles)} URLs to 'found_articles_all_strategies.txt'")

    return unique_articles


def main():
    """Main entry point"""
    print("\n" + "#"*80)
    print("# IMPROVED URL FINDER")
    print("#"*80)

    # Example: Try mining.com with all strategies
    base_url = "https://www.mining.com"

    articles = try_multiple_strategies(base_url)

    if articles:
        print("\n✅ Success! Found iron ore articles")
        print("\nNext step: Use these URLs with the scraper:")
        print("  from iron_ore_scraper import IronOreForecastScraper")
        print("  scraper = IronOreForecastScraper()")
        print("  urls = [article['url'] for article in articles]")
        print("  scraper.scrape_urls(urls)")
    else:
        print("\n❌ No articles found")
        print("\nTroubleshooting:")
        print("  1. Run debug_crawler.py to see what's happening")
        print("  2. Try a more specific starting URL")
        print("  3. Manually browse the site to find article URLs")


if __name__ == "__main__":
    main()
