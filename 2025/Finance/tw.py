import pandas as pd
import matplotlib.pyplot as plt

# Simulate Taiwan's nominal GDP per capita in USD (historical data)
years = list(range(2010, 2025))
gdp_per_capita_usd = [19200, 20200, 21250, 22500, 23500, 24800, 26500, 27800, 29100, 30300, 31800, 32700, 33000, 33200, 32750, 34430]

# Simulate historical average annual gold price in USD (per ounce)
gold_price_usd = [1224, 1669, 1670, 1411, 1266, 1160, 1250, 1257, 1268, 1393, 1770, 1800, 1890, 1932, 2100, 3400]

# Calculate GDP per capita in gold ounces
gdp_per_capita_in_gold = [gdp/gold for gdp, gold in zip(gdp_per_capita_usd, gold_price_usd)]

# Create a DataFrame for plotting
df = pd.DataFrame({
    'Year': years,
    'GDP per Capita (USD)': gdp_per_capita_usd,
    'Gold Price (USD)': gold_price_usd,
    'GDP per Capita (Gold Ounces)': gdp_per_capita_in_gold
})

# Plotting
plt.figure(figsize=(12, 6))
plt.plot(df['Year'], df['GDP per Capita (Gold Ounces)'], marker='o', linestyle='-', color='gold')
plt.title("Taiwan's GDP per Capita in Gold Ounces (2010–2024)")
plt.xlabel("Year")
plt.ylabel("GDP per Capita (Gold Ounces)")
plt.grid(True)
plt.tight_layout()
plt.show()

