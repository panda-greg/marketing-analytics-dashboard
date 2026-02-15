import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.engine.url import URL

db_url = URL.create(
    drivername="postgresql",
    username="postgres",
    password="$up@B4sE2026",  # Raw password, no encoding needed
    host="db.bwudeogkvmliqvsqidps.supabase.co",
    port=5432,
    database="postgres"
)

engine = create_engine(db_url)

# Read and upload CSVs
facebook_df = pd.read_csv('01_facebook_ads.csv')
google_df = pd.read_csv('02_google_ads.csv')
tiktok_df = pd.read_csv('03_tiktok_ads.csv')

# Upload to database
facebook_df.to_sql('facebook_ads', engine, if_exists='replace', index=False)
google_df.to_sql('google_ads', engine, if_exists='replace', index=False)
tiktok_df.to_sql('tiktok_ads', engine, if_exists='replace', index=False)

print("Upload complete!")