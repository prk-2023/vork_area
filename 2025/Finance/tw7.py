import pandas as pd
import matplotlib.pyplot as plt

# Historical nominal GDP per capita in USD (2010–2024)
years = list(range(2010, 2025))
gdp_per_capita_usd = [19200, 20200, 21250, 22500, 23500, 24800, 26500, 27800, 29100, 30300, 31800, 32700, 33000, 33200, 32750]

# Add 2025 nominal GDP per capita
years.append(2025)
gdp_per_capita_usd.append(34430)

# PPP GDP per capita for 2025 in TWD and conversion to USD
ppp_2025_twd = 84040
exchange_rate = 30  # Approximate TWD/USD rate
ppp_2025_usd = ppp_2025_twd / exchange_rate

# Average annual gold price in USD (per ounce) 2010–2024 (simulate)
gold_price_usd = [1224, 1669, 1670, 1411, 1266, 1160, 1250, 1257, 1268, 1393, 1770, 1800, 1890, 1932, 2100]
# Add estimated gold price for 2025 (let's assume 2200 USD)
###gold_price_usd.append(2200)
gold_price_usd.append(3400)

# Calculate GDP per capita in gold ounces for nominal GDP
gdp_per_capita_in_gold = [gdp/gold for gdp, gold in zip(gdp_per_capita_usd, gold_price_usd)]

# Calculate 2025 PPP GDP per capita in gold ounces (only for 2025, appended as a separate point)
ppp_2025_gold = ppp_2025_usd / gold_price_usd[-1]

# Create DataFrame for plotting
df = pd.DataFrame({
    'Year': years,
    'GDP per Capita (USD)': gdp_per_capita_usd,
    'Gold Price (USD)': gold_price_usd,
    'GDP per Capita (Gold Ounces)': gdp_per_capita_in_gold
})

# Plotting
plt.figure(figsize=(12, 6))
plt.plot(df['Year'], df['GDP per Capita (Gold Ounces)'], marker='o', linestyle='-', color='gold', label='Nominal GDP per Capita (Gold Ounces)')

# Plot PPP 2025 point
plt.scatter(2025, ppp_2025_gold, color='blue', s=100, label='PPP 2025 GDP per Capita (Gold Ounces)')

plt.title("Taiwan's GDP per Capita in Gold Ounces (2010–2025)")
plt.xlabel("Year")
plt.ylabel("GDP per Capita (Gold Ounces)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()

