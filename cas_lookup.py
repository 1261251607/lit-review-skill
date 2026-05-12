#!/usr/bin/env python3
"""Look up CAS journal partition by name or ISSN."""
import csv, sys, os

CSV_PATH = os.environ.get(
    "CAS_PARTITION_CSV",
    os.path.expanduser("~/.paper-fetcher/cas_partition/FQBJCR2025-UTF8.csv")
)

def load_table():
    """Load CAS partition table into memory, indexed by ISSN and normalized name."""
    table = {}
    with open(CSV_PATH, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            issn_raw = row.get('ISSN/EISSN', '')
            name = row.get('Journal', '').strip().upper()
            entry = {
                'name': row.get('Journal', '').strip(),
                'category': row.get('大类', '').strip(),
                'partition': row.get('大类分区', '').strip(),
                'top': row.get('Top', '否').strip() == '是',
                'subcat1': row.get('小类1', '').strip(),
                'subcat1_partition': row.get('小类1分区', '').strip(),
                'issns': issn_raw.replace(' ', ''),
            }
            # Index by ISSN
            for issn in issn_raw.split('/'):
                issn = issn.strip().upper()
                if issn:
                    table[issn] = entry
            # Index by name
            table[name] = entry
    return table

def lookup(journal_name=None, issn=None):
    """Look up a journal. Returns dict or None."""
    table = load_table()
    if issn:
        for key in [issn.upper(), issn.replace('-',''), issn]:
            if key in table:
                return table[key]
    if journal_name:
        # Exact match
        key = journal_name.upper().strip().rstrip('.')
        if key in table:
            return table[key]
        # Fuzzy: try matching first N chars
        for name, entry in table.items():
            if key in name or name in key:
                return entry
    return None

def format_result(result):
    """Format lookup result as a single-line summary."""
    if not result:
        return "未找到"
    parts = [
        f"{result['category']} {result['partition']}",
    ]
    if result['top']:
        parts.append("(Top期刊)")
    if result['subcat1']:
        parts.append(f"| {result['subcat1']} {result['subcat1_partition']}")
    return result['name'] + " — " + " ".join(parts)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 cas_lookup.py <journal_name_or_issn>")
        sys.exit(1)
    result = lookup(journal_name=sys.argv[1]) or lookup(issn=sys.argv[1])
    print(format_result(result))
