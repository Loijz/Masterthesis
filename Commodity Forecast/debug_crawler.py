"""
Debug version of the crawler to see what's happening
This helps identify why articles aren't being found
"""

from url_finder import IronOreArticleFinder


class DebugIronOreFinder(IronOreArticleFinder):
    """Debug version with detailed logging"""

    def __init__(self):
        super().__init__()
        self.debug_stats = {
            'total_pages_checked': 0,
            'article_urls_found': 0,
            'iron_ore_content_found': 0,
            'both_conditions_met': 0,
            'sample_urls_checked': [],
            'sample_titles_checked': [],
            'rejected_no_article_pattern': [],
            'rejected_no_keywords': []
        }

    def search_website(self, start_url: str, max_pages: int = 50, max_depth: int = 2):
        """Debug version with detailed logging"""
        print(f"\n{'='*80}")
        print(f"DEBUG CRAWLER - Searching {start_url}")
        print(f"{'='*80}")
        print(f"Max pages: {max_pages}, Max depth: {max_depth}\n")

        to_visit = [(start_url, 0)]
        pages_crawled = 0

        while to_visit and pages_crawled < max_pages:
            current_url, depth = to_visit.pop(0)

            if current_url in self.visited_urls or depth > max_depth:
                continue

            self.visited_urls.add(current_url)
            pages_crawled += 1
            self.debug_stats['total_pages_checked'] += 1

            print(f"\n[{pages_crawled}/{max_pages}] Depth {depth}: {current_url[:100]}")

            soup = self.fetch_page(current_url)
            if not soup:
                print("  ⚠ Failed to fetch page")
                continue

            # Get page info
            page_text = soup.get_text(separator=' ', strip=True)[:1000]
            title = soup.find('title')
            title_text = title.get_text() if title else ""

            # Store samples
            if len(self.debug_stats['sample_urls_checked']) < 10:
                self.debug_stats['sample_urls_checked'].append(current_url)
                self.debug_stats['sample_titles_checked'].append(title_text)

            # Check conditions separately
            is_article = self.is_article_url(current_url)
            has_keywords = self.contains_iron_ore_keywords(page_text + title_text, current_url)

            print(f"  📄 Title: {title_text[:70]}")
            print(f"  🔗 Is article URL pattern: {is_article}")
            print(f"  🔍 Has iron ore keywords: {has_keywords}")

            # Track stats
            if is_article:
                self.debug_stats['article_urls_found'] += 1
            if has_keywords:
                self.debug_stats['iron_ore_content_found'] += 1

            # Show why it was rejected
            if is_article and not has_keywords:
                print(f"  ❌ REJECTED: Article URL but no iron ore keywords")
                if len(self.debug_stats['rejected_no_keywords']) < 5:
                    self.debug_stats['rejected_no_keywords'].append({
                        'url': current_url,
                        'title': title_text,
                        'sample_text': page_text[:200]
                    })

            if has_keywords and not is_article:
                print(f"  ❌ REJECTED: Has keywords but URL doesn't match article pattern")
                if len(self.debug_stats['rejected_no_article_pattern']) < 5:
                    self.debug_stats['rejected_no_article_pattern'].append({
                        'url': current_url,
                        'title': title_text
                    })

            # Accept if both conditions met
            if is_article and has_keywords:
                article_info = {
                    'url': current_url,
                    'title': title_text.strip(),
                    'found_at_depth': depth
                }
                self.found_articles.append(article_info)
                self.debug_stats['both_conditions_met'] += 1
                print(f"  ✅ FOUND ARTICLE!")

            # Extract links
            if depth < max_depth:
                links = self.extract_links(soup, current_url)
                print(f"  🔗 Found {len(links)} links on this page")

                article_links = [l for l in links if self.is_article_url(l)]
                other_links = [l for l in links if not self.is_article_url(l)]

                print(f"     - {len(article_links)} look like articles")
                print(f"     - {len(other_links)} other links")

                for link in article_links + other_links:
                    if link not in self.visited_urls:
                        to_visit.append((link, depth + 1))

        self.print_debug_summary()
        return self.found_articles

    def print_debug_summary(self):
        """Print detailed debug summary"""
        print(f"\n{'='*80}")
        print(f"DEBUG SUMMARY")
        print(f"{'='*80}\n")

        stats = self.debug_stats
        print(f"Pages checked: {stats['total_pages_checked']}")
        print(f"Pages matching article URL pattern: {stats['article_urls_found']}")
        print(f"Pages with iron ore keywords: {stats['iron_ore_content_found']}")
        print(f"Pages matching BOTH (articles found): {stats['both_conditions_met']}")

        print(f"\n{'='*80}")
        print(f"SAMPLE URLs CHECKED")
        print(f"{'='*80}")
        for i, url in enumerate(stats['sample_urls_checked'][:5], 1):
            print(f"{i}. {url}")
            if i <= len(stats['sample_titles_checked']):
                print(f"   Title: {stats['sample_titles_checked'][i-1][:80]}")

        if stats['rejected_no_keywords']:
            print(f"\n{'='*80}")
            print(f"EXAMPLE: Article URLs WITHOUT Iron Ore Keywords")
            print(f"{'='*80}")
            for item in stats['rejected_no_keywords'][:3]:
                print(f"\nURL: {item['url']}")
                print(f"Title: {item['title'][:80]}")
                print(f"Sample text: {item['sample_text'][:150]}...")

        if stats['rejected_no_article_pattern']:
            print(f"\n{'='*80}")
            print(f"EXAMPLE: Pages WITH Keywords but NOT Article URL Pattern")
            print(f"{'='*80}")
            for item in stats['rejected_no_article_pattern'][:3]:
                print(f"\nURL: {item['url']}")
                print(f"Title: {item['title'][:80]}")

        print(f"\n{'='*80}")
        print(f"ARTICLE URL PATTERNS USED")
        print(f"{'='*80}")
        for pattern in self.article_patterns:
            print(f"  - {pattern}")

        print(f"\n{'='*80}")
        print(f"RECOMMENDATIONS")
        print(f"{'='*80}")

        if stats['article_urls_found'] == 0:
            print("\n⚠ No article URL patterns found!")
            print("   → The site might use different URL structures")
            print("   → Try targeting a specific news section (e.g., /news/ or /category/)")
            print("   → Check sample URLs above to see what patterns exist")

        if stats['iron_ore_content_found'] == 0:
            print("\n⚠ No iron ore content found!")
            print("   → Try different keywords")
            print("   → The site might not have iron ore forecast articles")
            print("   → Try a more specific starting URL")

        if stats['article_urls_found'] > 0 and stats['iron_ore_content_found'] > 0 and stats['both_conditions_met'] == 0:
            print("\n⚠ Found article URLs and iron ore content, but never together!")
            print("   → Try increasing max_depth to crawl deeper")
            print("   → Try starting from a more specific section")

        if stats['both_conditions_met'] > 0:
            print(f"\n✅ Success! Found {stats['both_conditions_met']} articles")


def main():
    """Run debug crawler"""
    print("\n" + "#"*80)
    print("# DEBUG CRAWLER - Find out why articles aren't being found")
    print("#"*80)

    # Change this to your target URL
    target_url = "https://www.mining.com"

    debug_finder = DebugIronOreFinder()
    debug_finder.search_website(
        start_url=target_url,
        max_pages=20,  # Start small for debugging
        max_depth=2
    )

    if debug_finder.found_articles:
        print(f"\n✅ Found {len(debug_finder.found_articles)} articles!")
        print("\nArticles found:")
        for article in debug_finder.found_articles:
            print(f"  - {article['title'][:70]}")
            print(f"    {article['url']}")
    else:
        print("\n❌ No articles found. Check recommendations above.")


if __name__ == "__main__":
    main()
