import pandas as pd
import matplotlib.pyplot as plt

def load_gold_data(file_path):
    """
    Load gold price data CSV with columns: Date, GoldPrice (USD)
    Date format: YYYY-MM-DD
    """
    df = pd.read_csv(file_path, parse_dates=['Date'])
    df.sort_values('Date', inplace=True)
    df.reset_index(drop=True, inplace=True)
    return df

def calculate_moving_average(df, window=50):
    df['MA'] = df['GoldPrice'].rolling(window=window).mean()
    return df

def plot_gold_with_ma(df):
    plt.figure(figsize=(12,6))
    plt.plot(df['Date'], df['GoldPrice'], label='Gold Price (USD)')
    plt.plot(df['Date'], df['MA'], label=f'{window}-Day Moving Average')
    plt.title('Gold Price with Moving Average')
    plt.xlabel('Date')
    plt.ylabel('Price (USD)')
    plt.legend()
    plt.grid(True)
    plt.show()

def buy_signal(df, threshold=0.95):
    """
    Simple signal:
    If current gold price < threshold * moving average, recommend buying.
    Suggest % allocation proportional to deviation.
    """
    latest_price = df['GoldPrice'].iloc[-1]
    latest_ma = df['MA'].iloc[-1]
    ratio = latest_price / latest_ma
    
    print(f"Latest Gold Price: {latest_price:.2f} USD")
    print(f"Latest Moving Average: {latest_ma:.2f} USD")
    print(f"Price / MA ratio: {ratio:.3f}")
    
    if ratio < threshold:
        # The more price deviates below MA, the higher % suggested to allocate (max 20%)
        diff = threshold - ratio
        allocation_pct = min(diff * 100, 20)
        print(f"Signal: BUY GOLD — Suggested allocation: {allocation_pct:.2f}% of portfolio")
    else:
        print("Signal: HOLD — No immediate buy suggested")

if __name__ == "__main__":
    # Example usage
    file_path = 'gold_price.csv'  # Your gold price data CSV file path
    window = 50  # moving average window in days
    
    df = load_gold_data(file_path)
    df = calculate_moving_average(df, window)
    plot_gold_with_ma(df)
    buy_signal(df, threshold=0.95)
