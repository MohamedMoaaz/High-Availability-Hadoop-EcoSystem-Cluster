from faker import Faker
from happybase import Connection
import random
from datetime import datetime, timedelta

# Initialize Faker
fake = Faker()

# Connect to HBase (adjust connection parameters as needed)
connection = Connection(host='localhost', port=9090)
table = connection.table('webtable')

# List of 5 domains
domains = ['example.com', 'test.org', 'demo.net', 'sample.edu', 'website.biz']

# Function to create properly padded and reversed domain row key
def create_row_key(url):
    # Remove protocol if present
    if '://' in url:
        url = url.split('://')[1]
    
    # Split into domain and path
    parts = url.split('/')
    domain = parts[0]
    path = '/'.join(parts[1:]) if len(parts) > 1 else ''
    
    # Reverse domain parts and pad each component
    domain_parts = domain.split('.')
    reversed_parts = []
    
    for part in reversed(domain_parts):
        # Pad each part to 10 characters with leading zeros
        padded_part = part.zfill(10)
        reversed_parts.append(padded_part)
    
    # Rebuild the reversed domain
    reversed_domain = '.'.join(reversed_parts)
    
    # Combine with path if it exists
    return f"{reversed_domain}:{path}" if path else reversed_domain

# Generate and insert 20 sample web pages
for i in range(20):
    # Randomly select a domain
    domain = random.choice(domains)
    
    # Generate URL path
    url_path = fake.uri_path()
    full_url = f"https://{domain}/{url_path}"
    row_key = create_row_key(full_url)
    
    # Generate random creation date (some recent, some older)
    if random.random() > 0.3:
        created_at = datetime.now() - timedelta(days=random.randint(1, 30))
    else:
        created_at = datetime.now() - timedelta(days=random.randint(90, 365))
    
    # Generate content of varying sizes
    content_sizes = {
        'small': fake.text(max_nb_chars=500),
        'medium': fake.text(max_nb_chars=2000),
        'large': fake.text(max_nb_chars=10000)
    }
    size = random.choice(['small', 'medium', 'large'])
    content = content_sizes[size]
    
    # Generate metadata
    metadata = {
        'title': fake.sentence(),
        'description': fake.text(max_nb_chars=160),
        'language': random.choice(['en', 'es', 'fr', 'de', 'zh']),
        'created_at': created_at.isoformat(),
        'last_modified': datetime.now().isoformat(),
        'content_type': 'text/html',
        'charset': 'UTF-8'
    }
    
    # Generate outbound links (3-10 random links)
    outlinks_count = random.randint(3, 10)
    outlinks = {}
    for j in range(outlinks_count):
        link_domain = random.choice(domains)
        link_url = f"https://{link_domain}/{fake.uri_path()}"
        outlinks[f"link_{j}"] = link_url
    
    # Generate inbound links (simulate some pages linking to this one)
    inlinks = {}
    if i > 5 and random.random() > 0.7:  # Only some pages have inbound links
        inlinks_count = random.randint(1, 5)
        for k in range(inlinks_count):
            source_domain = random.choice(domains)
            source_url = f"https://{source_domain}/{fake.uri_path()}"
            inlinks[f"source_{k}"] = source_url
    
    # Prepare data for HBase
    data = {}
    
    # Content family
    data[b'content:html'] = content.encode('utf-8')
    
    # Metadata family
    for key, value in metadata.items():
        data[f'metadata:{key}'.encode('utf-8')] = str(value).encode('utf-8')
    
    # Outlinks family
    for key, value in outlinks.items():
        data[f'outlinks:{key}'.encode('utf-8')] = value.encode('utf-8')
    
    # Inlinks family
    for key, value in inlinks.items():
        data[f'inlinks:{key}'.encode('utf-8')] = value.encode('utf-8')
    
    # Insert into HBase
    table.put(row_key.encode('utf-8'), data)
    print(f"Inserted: {row_key}")

connection.close()
print("Data generation complete!")
