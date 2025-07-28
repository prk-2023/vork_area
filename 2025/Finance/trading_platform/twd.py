import requests
import pandas as pd
import matplotlib.pyplot as plt
import twse_py  # The Rust module

def fetch_usd_twd():
    url = "https://open.er-api.com/v6/latest/USD"
    response = requests.get(url)
    data = response.json()
    twd_rate = data['rates']['TWD']
    return twd_rate

def simple_moving_average(prices, window=5):
    return pd.Series(prices).rolling(window=window).mean()

def main():
    # Fetch live TSMC stock price from Rust module
    stock_code = "2330"
    stock_data = twse_py.fetch_twse_stock(stock_code)
    if stock_data:
        code, name, price = stock_data
        print(f"{code} {name} latest price: {price}")
    else:
        print("Failed to fetch stock data")
        return

    # Fetch USD/TWD exchange rate
    usd_twd = fetch_usd_twd()
    print(f"USD/TWD exchange rate: {usd_twd}")

    # For demo: simulate last 10 closing prices (mock data)
    prices = [price * (1 + 0.01 * i) for i in range(-9, 1)]  # Simulated increasing prices
    sma = simple_moving_average(prices, window=3)

    # Plot prices and SMA
    plt.plot(prices, label='Price')
    plt.plot(sma, label='SMA (3)')
    plt.title(f'{name} Price and SMA')
    plt.legend()
    plt.show()

if __name__ == "__main__":
    main()
