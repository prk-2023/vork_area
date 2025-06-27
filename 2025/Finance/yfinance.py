import yfinance as yf

# Download gold futures daily price data (max history available)
gold = yf.download('GC=F', start='1970-01-01', progress=False)

# Keep only 'Close' price and reset index
gold = gold[['Close']].reset_index()
gold.rename(columns={'Date': 'Date', 'Close': 'GoldPrice'}, inplace=True)

# Save to CSV
gold.to_csv('gold_price_50years.csv', index=False)

print("Downloaded gold price data saved to gold_price_50years.csv")

