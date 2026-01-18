"""
Reddit Scraper - Iron Ore Discussions and Forecasts
Uses Reddit's JSON API (no authentication required for public data)
"""

import requests
import time
from datetime import datetime
import json


def search_reddit_posts(query, subreddit=None, max_results=100, sort='relevance', time_filter='all'):
    """
    Search Reddit for posts using JSON API

    Args:
        query: Search term (e.g., "iron ore forecast")
        subreddit: Specific subreddit or None for all
        max_results: Maximum posts to retrieve
        sort: 'relevance', 'hot', 'top', 'new', 'comments'
        time_filter: 'all', 'year', 'month', 'week', 'day'
    """
    print(f"\n{'='*80}")
    print(f"SEARCHING REDDIT FOR: '{query}'")
    print(f"{'='*80}")

    all_posts = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'IronOreResearchBot/1.0 (Educational Research)'
    })

    # Build search URL
    if subreddit:
        base_url = f"https://www.reddit.com/r/{subreddit}/search.json"
    else:
        base_url = "https://www.reddit.com/search.json"

    params = {
        'q': query,
        'sort': sort,
        't': time_filter,
        'limit': 25,  # Reddit's max per request
        'restrict_sr': 'true' if subreddit else 'false',
    }

    after = None  # Pagination cursor
    retrieved = 0

    print(f"Subreddit: {subreddit if subreddit else 'All'}")
    print(f"Sort: {sort}, Time: {time_filter}")
    print(f"Max results: {max_results}\n")

    while retrieved < max_results:
        if after:
            params['after'] = after

        try:
            print(f"Fetching posts {retrieved+1}-{min(retrieved+25, max_results)}... ", end='', flush=True)

            response = session.get(base_url, params=params, timeout=30)

            if response.status_code == 429:
                print("Rate limited, waiting 60 seconds...")
                time.sleep(60)
                continue

            response.raise_for_status()

            data = response.json()
            posts = data.get('data', {}).get('children', [])

            if not posts:
                print("No more posts found")
                break

            for post in posts:
                post_data = post.get('data', {})
                all_posts.append({
                    'title': post_data.get('title', ''),
                    'selftext': post_data.get('selftext', ''),
                    'subreddit': post_data.get('subreddit', ''),
                    'author': post_data.get('author', ''),
                    'score': post_data.get('score', 0),
                    'num_comments': post_data.get('num_comments', 0),
                    'created_utc': post_data.get('created_utc', 0),
                    'url': f"https://www.reddit.com{post_data.get('permalink', '')}",
                    'is_self': post_data.get('is_self', True),
                })

            retrieved += len(posts)
            after = data.get('data', {}).get('after')

            print(f"found {len(posts)} posts (total: {retrieved})")

            if not after:
                print("No more pages available")
                break

            time.sleep(2)  # Reddit rate limiting - be polite

        except Exception as e:
            print(f"Error: {e}")
            break

    print(f"\n→ Total posts retrieved: {len(all_posts)}")
    return all_posts


def get_subreddit_posts(subreddit, sort='new', limit=100):
    """
    Get posts from a specific subreddit

    Args:
        subreddit: Subreddit name
        sort: 'hot', 'new', 'top', 'rising'
        limit: Maximum posts
    """
    print(f"\n{'='*80}")
    print(f"GETTING POSTS FROM r/{subreddit}")
    print(f"{'='*80}")

    all_posts = []

    session = requests.Session()
    session.headers.update({
        'User-Agent': 'IronOreResearchBot/1.0 (Educational Research)'
    })

    base_url = f"https://www.reddit.com/r/{subreddit}/{sort}.json"

    params = {
        'limit': 25,
    }

    after = None
    retrieved = 0

    print(f"Sort: {sort}, Limit: {limit}\n")

    while retrieved < limit:
        if after:
            params['after'] = after

        try:
            print(f"Fetching posts {retrieved+1}-{min(retrieved+25, limit)}... ", end='', flush=True)

            response = session.get(base_url, params=params, timeout=30)

            if response.status_code == 429:
                print("Rate limited, waiting 60 seconds...")
                time.sleep(60)
                continue

            if response.status_code == 404:
                print(f"Subreddit r/{subreddit} not found")
                break

            response.raise_for_status()

            data = response.json()
            posts = data.get('data', {}).get('children', [])

            if not posts:
                print("No more posts")
                break

            for post in posts:
                post_data = post.get('data', {})
                all_posts.append({
                    'title': post_data.get('title', ''),
                    'selftext': post_data.get('selftext', ''),
                    'subreddit': post_data.get('subreddit', ''),
                    'author': post_data.get('author', ''),
                    'score': post_data.get('score', 0),
                    'num_comments': post_data.get('num_comments', 0),
                    'created_utc': post_data.get('created_utc', 0),
                    'url': f"https://www.reddit.com{post_data.get('permalink', '')}",
                    'is_self': post_data.get('is_self', True),
                })

            retrieved += len(posts)
            after = data.get('data', {}).get('after')

            print(f"found {len(posts)} posts (total: {retrieved})")

            if not after:
                break

            time.sleep(2)

        except Exception as e:
            print(f"Error: {e}")
            break

    return all_posts


def filter_iron_ore_posts(posts):
    """
    Filter posts for iron ore content
    """
    print(f"\n{'='*80}")
    print(f"FILTERING {len(posts)} POSTS FOR IRON ORE CONTENT")
    print(f"{'='*80}")

    iron_ore_keywords = [
        'iron ore', 'iron-ore', 'ironore',
        'fe62', '62% fe', 'iron ore price',
        'cfr china', 'platts iron',
        'vale', 'rio tinto', 'bhp', 'fortescue',
        'pilbara', 'carajas'
    ]

    forecast_keywords = [
        'forecast', 'prediction', 'outlook', 'expect',
        'price target', 'will reach', 'going to',
        'by 2024', 'by 2025', 'next year',
        'bull', 'bear', 'rally', 'crash'
    ]

    filtered = []

    for post in posts:
        text = (post['title'] + ' ' + post['selftext']).lower()

        has_iron_ore = any(kw in text for kw in iron_ore_keywords)
        has_forecast = any(kw in text for kw in forecast_keywords)

        if has_iron_ore:
            post['has_forecast_keywords'] = has_forecast
            filtered.append(post)

    print(f"  Posts with iron ore content: {len(filtered)}")
    forecast_posts = [p for p in filtered if p.get('has_forecast_keywords')]
    print(f"  Posts with forecast keywords: {len(forecast_posts)}")

    return filtered


def search_iron_ore_comprehensive():
    """
    Comprehensive search for iron ore forecasts on Reddit
    """
    print("\n" + "#"*80)
    print("# REDDIT IRON ORE COMPREHENSIVE SEARCH")
    print("#"*80)

    all_posts = []

    # Strategy 1: Direct searches
    print("\n" + "="*80)
    print("STRATEGY 1: Search Queries")
    print("="*80)

    search_queries = [
        "iron ore forecast",
        "iron ore price prediction",
        "iron ore outlook",
        "iron ore 2024",
        "iron ore 2025",
        "iron ore bull bear",
        "BHP Rio Tinto iron ore",
        "Vale iron ore price",
    ]

    for query in search_queries:
        posts = search_reddit_posts(query, max_results=50, sort='relevance', time_filter='all')
        all_posts.extend(posts)
        time.sleep(3)  # Be polite

    # Strategy 2: Relevant subreddits
    print("\n" + "="*80)
    print("STRATEGY 2: Relevant Subreddits")
    print("="*80)

    subreddits = [
        ('commodities', 'Search for iron ore'),
        ('investing', 'Search for iron ore'),
        ('stocks', 'Search for BHP Rio Tinto Vale'),
        ('wallstreetbets', 'Search for iron ore steel'),
        ('mining', 'Search for iron ore'),
        ('AusFinance', 'Search for iron ore BHP'),
    ]

    for subreddit, search_term in subreddits:
        print(f"\nSearching r/{subreddit}...")
        try:
            posts = search_reddit_posts(
                search_term.replace('Search for ', ''),
                subreddit=subreddit,
                max_results=50,
                sort='relevance'
            )
            all_posts.extend(posts)
            time.sleep(3)
        except Exception as e:
            print(f"  Error with r/{subreddit}: {e}")

    # Remove duplicates based on URL
    print(f"\n{'='*80}")
    print("REMOVING DUPLICATES")
    print(f"{'='*80}")

    unique_posts = {}
    for post in all_posts:
        if post['url'] not in unique_posts:
            unique_posts[post['url']] = post

    all_posts = list(unique_posts.values())
    print(f"  Total unique posts: {len(all_posts)}")

    # Filter for iron ore content
    iron_ore_posts = filter_iron_ore_posts(all_posts)

    return iron_ore_posts


def save_reddit_posts(posts, filename_prefix='reddit_iron_ore'):
    """
    Save Reddit posts to files
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")

    # Save as JSON (full data)
    json_file = f'{filename_prefix}_{timestamp}.json'
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(posts, f, indent=2)
    print(f"✓ Saved {len(posts)} posts to {json_file}")

    # Save as CSV (for easy viewing)
    csv_file = f'{filename_prefix}_{timestamp}.csv'
    with open(csv_file, 'w', encoding='utf-8', newline='') as f:
        import csv
        writer = csv.writer(f)
        writer.writerow([
            'title', 'subreddit', 'author', 'score', 'num_comments',
            'date', 'url', 'has_forecast_keywords', 'selftext_preview'
        ])

        for post in posts:
            # Convert timestamp
            date = datetime.utcfromtimestamp(post['created_utc']).strftime('%Y-%m-%d')

            # Preview of text (first 200 chars)
            text_preview = post['selftext'][:200].replace('\n', ' ') if post['selftext'] else ''

            writer.writerow([
                post['title'],
                post['subreddit'],
                post['author'],
                post['score'],
                post['num_comments'],
                date,
                post['url'],
                post.get('has_forecast_keywords', False),
                text_preview
            ])

    print(f"✓ Saved CSV to {csv_file}")

    # Save URLs only (for scraping with iron_ore_scraper)
    urls_file = f'{filename_prefix}_urls_{timestamp}.txt'
    with open(urls_file, 'w', encoding='utf-8') as f:
        f.write(f"# Reddit Iron Ore Posts\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Total posts: {len(posts)}\n")
        f.write("#\n")
        for post in posts:
            f.write(post['url'] + '\n')

    print(f"✓ Saved URLs to {urls_file}")

    return json_file, csv_file, urls_file


def extract_forecasts_from_reddit(posts):
    """
    Extract forecast information directly from Reddit posts
    (Uses the same patterns as iron_ore_scraper but adapted for Reddit)
    """
    print(f"\n{'='*80}")
    print(f"EXTRACTING FORECASTS FROM {len(posts)} REDDIT POSTS")
    print(f"{'='*80}")

    import re

    forecasts = []

    # Price patterns
    price_patterns = [
        r'\$(\d+(?:\.\d{1,2})?)\s*(?:per|/|a)?\s*(?:tonne|ton|mt|t)?',
        r'(\d+(?:\.\d{1,2})?)\s*(?:USD|dollars)',
        r'price[s]?\s+(?:of|at|to|around|near)\s+\$?(\d+(?:\.\d{1,2})?)',
    ]

    # Date patterns
    date_patterns = [
        r'(?:in|by|for)\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})',
        r'(?:in|by|for|end of)\s+(\d{4})',
        r'(Q[1-4])\s+(\d{4})',
        r'next\s+(year|quarter|month)',
    ]

    for post in posts:
        text = post['title'] + ' ' + post['selftext']
        text_lower = text.lower()

        # Check for iron ore mention
        if 'iron ore' not in text_lower and 'iron-ore' not in text_lower:
            continue

        # Extract prices
        prices_found = []
        for pattern in price_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                try:
                    if isinstance(match, tuple):
                        price = float(match[0])
                    else:
                        price = float(match)

                    # Filter reasonable iron ore prices
                    if 20 <= price <= 300:
                        prices_found.append(price)
                except:
                    pass

        # Extract dates
        dates_found = []
        for pattern in date_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                if isinstance(match, tuple):
                    dates_found.append(' '.join(match))
                else:
                    dates_found.append(match)

        # If we found prices and dates, this is likely a forecast
        if prices_found and dates_found:
            post_date = datetime.utcfromtimestamp(post['created_utc']).strftime('%Y-%m-%d')

            forecasts.append({
                'source': 'Reddit',
                'subreddit': post['subreddit'],
                'post_date': post_date,
                'url': post['url'],
                'title': post['title'][:100],
                'prices_mentioned': prices_found,
                'dates_mentioned': dates_found,
                'score': post['score'],
                'num_comments': post['num_comments'],
                'context': text[:500]
            })

    print(f"  Forecasts extracted: {len(forecasts)}")

    # Save forecasts
    if forecasts:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")

        # JSON
        with open(f'reddit_forecasts_{timestamp}.json', 'w', encoding='utf-8') as f:
            json.dump(forecasts, f, indent=2)

        # CSV
        import csv
        with open(f'reddit_forecasts_{timestamp}.csv', 'w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                'source', 'subreddit', 'post_date', 'url', 'title',
                'prices', 'dates', 'score', 'comments', 'context'
            ])
            for fc in forecasts:
                writer.writerow([
                    fc['source'],
                    fc['subreddit'],
                    fc['post_date'],
                    fc['url'],
                    fc['title'],
                    ', '.join(map(str, fc['prices_mentioned'])),
                    ', '.join(fc['dates_mentioned']),
                    fc['score'],
                    fc['num_comments'],
                    fc['context'][:300].replace('\n', ' ')
                ])

        print(f"✓ Saved forecasts to reddit_forecasts_{timestamp}.csv")
        print(f"✓ Saved forecasts to reddit_forecasts_{timestamp}.json")

    return forecasts


def main():
    """Main workflow"""
    print("\n" + "#"*80)
    print("# REDDIT IRON ORE SCRAPER")
    print("#"*80)
    print("\nReddit provides:")
    print("  - Community discussions on iron ore")
    print("  - Price predictions and market sentiment")
    print("  - Real-time market reactions")
    print("  - Historical discussions (searchable)")
    print("\nNote: Reddit is more casual/speculative than professional sources")
    print("Quality varies - use as supplementary data\n")

    print("What would you like to do?")
    print("1. Comprehensive search (multiple queries + subreddits)")
    print("2. Search specific query")
    print("3. Browse specific subreddit")

    choice = input("\nEnter choice (1-3): ").strip()

    if choice == "1":
        posts = search_iron_ore_comprehensive()

        if posts:
            # Save posts
            json_file, csv_file, urls_file = save_reddit_posts(posts)

            print(f"\n{'='*80}")
            print("RESULTS")
            print(f"{'='*80}")
            print(f"Total iron ore posts found: {len(posts)}")
            print(f"\nFiles created:")
            print(f"  - {json_file} (full data)")
            print(f"  - {csv_file} (spreadsheet)")
            print(f"  - {urls_file} (URLs only)")

            # Show top posts
            print(f"\nTop posts by score:")
            sorted_posts = sorted(posts, key=lambda x: x['score'], reverse=True)
            for i, post in enumerate(sorted_posts[:10], 1):
                date = datetime.utcfromtimestamp(post['created_utc']).strftime('%Y-%m-%d')
                print(f"{i:2d}. [{post['score']:4d}] r/{post['subreddit']}: {post['title'][:60]}...")
                print(f"    {date} | {post['num_comments']} comments | {post['url']}")

            # Extract forecasts
            extract = input("\nExtract forecast data from posts? (y/n): ").strip().lower()
            if extract == 'y':
                extract_forecasts_from_reddit(posts)

        else:
            print("\n✗ No posts found")

    elif choice == "2":
        query = input("\nEnter search query: ").strip()
        max_results = input("Max results (default 100): ").strip()
        max_results = int(max_results) if max_results.isdigit() else 100

        posts = search_reddit_posts(query, max_results=max_results)

        if posts:
            iron_ore_posts = filter_iron_ore_posts(posts)
            save_reddit_posts(iron_ore_posts, f'reddit_search_{query.replace(" ", "_")}')

    elif choice == "3":
        subreddit = input("\nEnter subreddit name (without r/): ").strip()
        limit = input("Number of posts (default 100): ").strip()
        limit = int(limit) if limit.isdigit() else 100

        posts = get_subreddit_posts(subreddit, limit=limit)

        if posts:
            iron_ore_posts = filter_iron_ore_posts(posts)

            if iron_ore_posts:
                save_reddit_posts(iron_ore_posts, f'reddit_{subreddit}')
            else:
                print(f"\nNo iron ore related posts found in r/{subreddit}")


if __name__ == "__main__":
    main()
