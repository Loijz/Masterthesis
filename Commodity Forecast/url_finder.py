"""
URL Finder - Discovers iron ore forecast articles on websites
Helps you find relevant article URLs to scrape
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import re
from typing import List, Set
import time


class IronOreArticleFinder:
    """Finds iron ore forecast articles on websites"""

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        self.visited_urls: Set[str] = set()
        self.found_articles: List[dict] = []

        # Keywords that indicate iron ore forecast content
        self.keywords = [
            'iron ore', 'iron-ore', 'ironore',
            'forecast', 'outlook', 'prediction',
            'price', 'prices', '62%', 'fe62'
        ]

        # URL patterns that likely contain articles
        self.article_patterns = [
            r'/news/',
            r'/article',
            r'/insights/',
            r'/analysis/',
            r'/market-insights/',
            r'/commodities/',
            r'/metals/',
            r'/mining/',
            r'/\d{4}/\d{2}/',  # Date-based URLs
            r'/web/',  # mining.com uses /web/ for articles
            r'/[a-z\-]+-[a-z\-]+-[a-z\-]+/',  # Matches URLs with multiple hyphens (common article pattern)
        ]

    def fetch_page(self, url: str) -> BeautifulSoup:
        """Fetch and parse a webpage"""
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            return BeautifulSoup(response.content, 'html.parser')
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None

    def is_article_url(self, url: str) -> bool:
        """Check if URL looks like an article"""
        return any(re.search(pattern, url, re.IGNORECASE) for pattern in self.article_patterns)

    def contains_iron_ore_keywords(self, text: str, url: str) -> bool:
        """Check if text or URL contains iron ore keywords"""
        text_lower = text.lower()
        url_lower = url.lower()

        # Must contain "iron ore" or "iron-ore"
        iron_ore_found = any(keyword in text_lower or keyword in url_lower
                            for keyword in ['iron ore', 'iron-ore', 'ironore'])

        if not iron_ore_found:
            return False

        # Should also contain forecast-related keywords
        forecast_found = any(keyword in text_lower or keyword in url_lower
                           for keyword in [
                               'forecast', 'outlook', 'prediction', 'expect',
                               'plummeted', 'raise', 'fall', 'increasing',
                               'long-term', 'short-term'
                           ])

        return iron_ore_found and forecast_found

    def extract_links(self, soup: BeautifulSoup, base_url: str) -> List[str]:
        """Extract all links from a page"""
        links = []
        for link in soup.find_all('a', href=True):
            url = urljoin(base_url, link['href'])

            # Keep only same domain
            if urlparse(url).netloc == urlparse(base_url).netloc:
                # Remove fragments and queries for deduplication
                url_clean = url.split('#')[0].split('?')[0]
                links.append(url_clean)

        return list(set(links))

    def search_website(self, start_url: str, max_pages: int = 50, max_depth: int = 2):
        """
        Search a website for iron ore forecast articles

        Args:
            start_url: Starting URL (e.g., homepage or news section)
            max_pages: Maximum number of pages to crawl
            max_depth: How many levels deep to crawl (1 = only start page, 2 = start + linked pages)
        """
        print(f"\nSearching {start_url} for iron ore forecast articles...")
        print(f"Max pages: {max_pages}, Max depth: {max_depth}")

        to_visit = [(start_url, 0)]  # (url, depth)
        pages_crawled = 0

        while to_visit and pages_crawled < max_pages:
            current_url, depth = to_visit.pop(0)

            # Skip if already visited or too deep
            if current_url in self.visited_urls or depth > max_depth:
                continue

            self.visited_urls.add(current_url)
            pages_crawled += 1

            print(f"[{pages_crawled}/{max_pages}] Crawling: {current_url[:80]}...")

            soup = self.fetch_page(current_url)
            if not soup:
                continue

            # Check if this page itself is an article about iron ore
            page_text = soup.get_text(separator=' ', strip=True)[:1000]  # First 1000 chars
            title = soup.find('title')
            title_text = title.get_text() if title else ""

            if self.is_article_url(current_url) and self.contains_iron_ore_keywords(page_text + title_text, current_url):
                article_info = {
                    'url': current_url,
                    'title': title_text.strip(),
                    'found_at_depth': depth
                }
                self.found_articles.append(article_info)
                print(f"  ✓ Found article: {title_text[:60]}...")

            # Extract and queue more links if not at max depth
            if depth < max_depth:
                links = self.extract_links(soup, current_url)

                # Prioritize article-looking URLs
                article_links = [l for l in links if self.is_article_url(l)]
                other_links = [l for l in links if not self.is_article_url(l)]

                # Add article links first, then others
                for link in article_links + other_links:
                    if link not in self.visited_urls:
                        to_visit.append((link, depth + 1))

            time.sleep(1)  # Be polite

        print(f"\nSearch complete!")
        print(f"Pages crawled: {pages_crawled}")
        print(f"Articles found: {len(self.found_articles)}")

        return self.found_articles

    def search_news_section(self, news_url: str, max_articles: int = 30):
        """
        Search a news/articles section for iron ore content
        Better for sites with news archives

        Args:
            news_url: URL to news section (e.g., https://www.mining.com/news/)
            max_articles: Maximum articles to check
        """
        print(f"\nSearching news section: {news_url}")

        soup = self.fetch_page(news_url)
        if not soup:
            return []

        # Find all article links
        links = self.extract_links(soup, news_url)
        article_links = [l for l in links if self.is_article_url(l)][:max_articles]

        print(f"Found {len(article_links)} potential article links, checking content...")

        checked = 0
        for url in article_links:
            if url in self.visited_urls:
                continue

            self.visited_urls.add(url)
            checked += 1

            print(f"[{checked}/{len(article_links)}] Checking: {url[:80]}...")

            soup = self.fetch_page(url)
            if not soup:
                continue

            page_text = soup.get_text(separator=' ', strip=True)[:1000]
            title = soup.find('title')
            title_text = title.get_text() if title else ""

            if self.contains_iron_ore_keywords(page_text + title_text, url):
                article_info = {
                    'url': url,
                    'title': title_text.strip(),
                    'source': news_url
                }
                self.found_articles.append(article_info)
                print(f"  ✓ Found: {title_text[:60]}...")

            time.sleep(1)

        print(f"\nFound {len(self.found_articles)} relevant articles")
        return self.found_articles

    def save_results(self, filename: str = 'found_article_urls.txt'):
        """Save found URLs to a file"""
        if not self.found_articles:
            print("No articles to save")
            return

        with open(filename, 'w', encoding='utf-8') as f:
            f.write("Iron Ore Forecast Articles Found\n")
            f.write("=" * 80 + "\n\n")

            for article in self.found_articles:
                f.write(f"Title: {article['title']}\n")
                f.write(f"URL: {article['url']}\n")
                f.write("-" * 80 + "\n")

        print(f"\nSaved {len(self.found_articles)} URLs to {filename}")

    def get_urls_list(self) -> List[str]:
        """Get list of found article URLs"""
        return [article['url'] for article in self.found_articles]


def main():
    """Example usage"""
    finder = IronOreArticleFinder()

    # Example 1: Search from a starting page
    # This will crawl the site starting from this URL
    # finder.search_website(
    #     "https://www.mining.com/category/commodities/",
    #     max_pages=30,
    #     max_depth=2
    # )

    # Example 2: Search a news section directly
    # finder.search_news_section(
    #     "https://www.reuters.com/markets/commodities/",
    #     max_articles=50
    # )

    # Save results
    # finder.save_results('iron_ore_article_urls.txt')

    # Get URLs for scraper
    # urls = finder.get_urls_list()
    # print(f"\nFound URLs:")
    # for url in urls:
    #     print(f"  {url}")

    print("\nURL Finder Usage:")
    print("-" * 60)
    print("\nMethod 1: Crawl from a starting page")
    print("  finder = IronOreArticleFinder()")
    print("  finder.search_website('https://example.com/news/', max_pages=30, max_depth=2)")
    print("\nMethod 2: Search a specific news section")
    print("  finder.search_news_section('https://example.com/commodities/', max_articles=50)")
    print("\nThen:")
    print("  finder.save_results('urls.txt')")
    print("  urls = finder.get_urls_list()")


if __name__ == "__main__":
    main()
