import yfinance as yf

def get_etf_holdings(etf_symbol="GLD"):
    etf = yf.Ticker(etf_symbol)
    hist = etf.history(period="30d")
    return hist[['Close', 'Volume']]

gld_data = get_etf_holdings("GLD")
print(gld_data.tail())

