#!/usr/bin/env python3
"""Tokenize research.references_urls for the reference provenance audit."""

import collections
import re
import sqlite3
import sys
import urllib.parse


DB_PATH = "/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db"
URL_RE = re.compile(r"https?://[^\s;,]+")


def main() -> int:
    db_path = sys.argv[1] if len(sys.argv) > 1 else DB_PATH
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    rows = conn.execute("select id, ts, references_urls from research order by id").fetchall()

    urls = []
    with_url_rows = 0
    non_url_nonblank_rows = 0
    by_day = collections.defaultdict(lambda: [0, 0, 0, 0])

    for row_id, ts, refs in rows:
        refs = refs or ""
        day = ts[:10]
        found = [url.rstrip(".,)") for url in URL_RE.findall(refs)]
        by_day[day][0] += 1
        if not refs.strip():
            by_day[day][1] += 1
        if found:
            with_url_rows += 1
            by_day[day][3] += 1
        elif refs.strip():
            non_url_nonblank_rows += 1
        by_day[day][2] += len(found)
        urls.extend((row_id, url) for url in found)

    by_url = collections.Counter(url for _, url in urls)
    by_domain = collections.Counter(
        urllib.parse.urlparse(url).netloc.lower() for _, url in urls
    )

    print("metric,value")
    print(f"research_rows,{len(rows)}")
    print(f"url_mentions,{len(urls)}")
    print(f"distinct_urls,{len(by_url)}")
    print(f"rows_with_url,{with_url_rows}")
    print(f"nonblank_rows_without_url,{non_url_nonblank_rows}")
    print()

    print("day,rows,blank_refs,url_mentions,rows_with_url")
    for day, values in sorted(by_day.items()):
        print(f"{day},{values[0]},{values[1]},{values[2]},{values[3]}")
    print()

    print("domain,url_mentions")
    for domain, count in by_domain.most_common(15):
        print(f"{domain},{count}")
    print()

    print("url,mentions")
    for url, count in by_url.most_common(15):
        print(f"{url},{count}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
