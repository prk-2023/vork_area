import yfinance as yf
import pandas as pd
import matplotlib.pyplot as plt

# Fetch data
tickers = ["GC=F", "^XAU"]  # GC=F (gold futures), XAUUSD=X (spot gold)
###data = yf.download(tickers, period="1y")["Close"]  # Use "Close" instead of "Adj Close"
# period : 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max, etc.
data = yf.download(tickers, period="max", auto_adjust=False)["Close"]  # Use "Close" instead of "Adj Close"

# Extract series
spot = data["^XAU"]  # Spot gold price (directly available in Yahoo Finance)
futures = data["GC=F"]   # Front-month gold futures (e.g., GC=F for continuous contract)

# Calculate basis
basis = futures - spot

# Plot
plt.figure(figsize=(12, 6))
plt.plot(basis, label="Futures Basis (Futures - Spot)", color="blue")
plt.axhline(0, color="red", linestyle="--", label="Contango/Backwardation Threshold")
plt.title("Gold Contango vs. Backwardation (Past 1 Year)")
plt.ylabel("Basis (USD per Ounce)")
plt.xlabel("Date")
plt.legend()
plt.grid(True)
plt.show()
