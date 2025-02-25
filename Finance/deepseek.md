# TODO:

## Q1.How to plot "near dated gold futures contract minus the spot gold price" and what can be concluded from this chart.

### **How to Plot "Near-Dated Gold Futures Contract Minus Spot Gold Price"**  

This spread, often called the **"basis"** or **"futures premium/discount,"** reflects the relationship 
between near-term futures prices and the spot price of gold. 

Here’s how to plot it:

#### **Step 1: Gather Data**  

- **Spot Gold Price**: 
  Obtain daily closing prices for physical gold (e.g., LBMA Gold Price or XAU/USD).

- **Near-Dated Futures Price**: 
  Use the front-month (closest to expiration) gold futures contract (e.g., COMEX GC1).  
- **Time Period**: 
  Choose a timeframe (e.g., 1 year, 5 years).  

#### **Step 2: Calculate the Basis**  

For each day:  
\[
\text{Basis} = \text{Near-Dated Futures Price} - \text{Spot Gold Price}  
\]

#### **Step 3: Plot the Spread**  
- **X-axis**: Time (daily/weekly).  
- **Y-axis**: Basis (in USD/ounce).  
- **Plot Type**: Line chart showing the basis over time.  

**Tools**: Use Excel, Python (Matplotlib/Pandas), or platforms like TradingView.  

---

### **Key Conclusions from the Plot**  

1. **Contango vs. Backwardation**:  

   - **Contango** (Futures > Spot): 
        Indicates the market expects gold prices to rise. 
        This often reflects storage costs, interest rates, and hedging demand.  
   - **Backwardation** (Futures < Spot): 
        Signals immediate scarcity or urgent demand for physical gold (rare in gold markets).  

2. **Market Sentiment**:  

   - A widening contango suggests traders are bullish long-term.  
   - A narrowing contango or shift to backwardation may signal short-term supply tightness or panic buying.  

3. **Arbitrage Opportunities**:  

   - If the basis exceeds storage + financing costs, traders can profit by buying spot and selling futures 
     ("cash-and-carry arbitrage").  

4. **Stress Signals**:  

   - Extreme backwardation (e.g., during crises like 2008 or 2020) often precedes gold price surges as 
     investors rush for safety.  

5. **Impact of Interest Rates**:  

   - Higher interest rates widen contango (due to higher carry costs).  
   - Lower rates compress contango.  

---

### **Can It Predict Gold Price Trends?**  

The basis alone is **not a crystal ball**, but it provides critical clues:  

#### **1. Short-Term Predictive Power**  

- **Backwardation as a Bullish Signal**:  

  Persistent backwardation (rare for gold) often precedes price spikes. 
  For example, in March 2020, gold briefly flipped to backwardation as COVID-19 panic drove physical demand,
  and prices surged afterward.  

- **Contango Collapse**:  
  A sudden narrowing of contango (e.g., due to futures selling) may signal short-term bearish sentiment.  

#### **2. Long-Term Trends**  

- **Sustained Contango**: Reflects confidence in stable prices.  
- **Structural Shifts**: A multi-year decline in contango could indicate systemic distrust in fiat 
  currencies, favoring gold.  

#### **3. Limitations**  

- **Noise vs. Signal**: Daily basis fluctuations are often noise (e.g., due to contract rollovers).
  Focus on sustained trends.  
- **Macro Drivers**: Gold prices are more influenced by interest rates, inflation, USD strength, and 
  geopolitics. The basis is a secondary indicator.  

---

### **Example: 2020 COVID-19 Crisis**  

- **What Happened**:  
  Gold briefly entered backwardation in March 2020 as investors scrambled for physical metal, while futures 
  sold off due to liquidity needs.  
- **Outcome**:  
  Gold prices surged 25% in the following 6 months as central banks unleashed stimulus.  

#### **Plot Interpretation**  
A backwardation spike during panic (March 2020) → Strong buy signal.  

---

### **Practical Use for Traders**  

1. **Futures Roll Yield**:  

   - In contango, rolling futures contracts incurs a cost (negative roll yield).  
   - In backwardation, rolling generates a profit (positive roll yield).  

2. **Sentiment Gauge**:  

   - Combine basis analysis with COT (Commitment of Traders) reports to see if commercial hedgers (miners) 
     are selling futures (bearish) or buying (bullish).  

3. **Divergence Alerts**:  
   - If spot gold rises while futures lag (basis narrows), it may signal physical demand outpacing paper 
     markets.  

---

### **Conclusion**  

Plotting the near-dated futures basis against spot gold helps identify:  
- Market structure (contango/backwardation).  
- Short-term supply/demand imbalances.  
- Sentiment extremes.  

While it can’t predict gold prices in isolation, **sustained backwardation or extreme contango shifts** 
often foreshadow volatility. 
Pair this analysis with macro indicators (real interest rates, USD index, inflation expectations) for a 
clearer gold trend outlook.  

**Final Tip**: 
    Watch for backwardation during crises—it’s like a "check engine light" for gold markets.

    It doesn’t tell you exactly what’s wrong, but it warns you to investigate further before the issue 
    escalates.

    Backwardation in gold futures (when near-term futures trade below the spot price) is a rare and abnormal
    condition that signals stress in the gold market. 
    It doesn’t predict exactly what will happen next, but it flashes a warning that:

        - Physical gold demand is surging.
        - Trust in paper assets (currencies, bonds, or even "paper gold" like ETFs) is eroding.
        - A crisis may be brewing beneath the surface.


** Why Backwardation Is a Crisis Signal**  
Gold markets are *usually* in **contango** (futures prices > spot prices) because of costs like storage, 
insurance, and interest rates. When this flips to backwardation, it means:  

    - **Urgent demand for physical gold**: 
      Buyers want bullion *now*, not later, and are willing to pay a premium for immediate delivery.  
    - **Distrust in financial systems**: 
      Investors may fear bank failures, currency devaluation, or derivatives defaults, driving a flight to 
      tangible assets.  
    - **Liquidity crunches**: 
      Sellers of futures contracts (e.g., banks or speculators) might be dumping paper gold to raise cash, 
      while physical buyers hoard metal.  

### ** Historical Examples**  
####**2008 Global Financial Crisis**  

- Au briefly entered backwardation in late 2008 as investors scrambled for physical amid bank collapses.  
- **Result**: Gold prices surged 166% over the next 3 years as central banks launched QE and rates hit zero.  

#### **March 2020 COVID-19 Crash**  

- Futures sold off violently as hedge funds liquidated paper gold to cover stock market losses, while 
  physical buyers (ex: central banks, retail investors) hoarded bullion creating a temporary backwardation.  

- **Result**: Gold prices rose 25% in 6 months as the Fed flooded markets with liquidity.  

#### **2022 (Russia-Ukraine War, Inflation Surge)**  

- While not full backwardation, the Au basis narrowed sharply as inflation fears spiked demand for physical.  
- **Result**: Gold hit all-time highs in 2023.  

---

### ** What Should Investors Do When the "Check Engine Light" Flashes?**  

1. **Don’t panic, but pay attention**:
    Backwardation doesn’t guarantee a meltdown, but it’s a sign to assess risks.  

2. **Check other indicators**:  
   - Rising inflation expectations.  
   - Falling real interest rates.  
   - Geopolitical tensions or banking stress.  

3. **Consider increasing physical gold exposure**: 
    Allocate to bullion, coins, or physically backed ETFs (e.g., GLD).  

4. **Avoid leveraged paper gold**: Futures and unallocated gold accounts could face liquidity squeezes.  

---

### **5. Limitations of the Signal**  

- **Temporary vs. Sustained Backwardation**: 
    A brief flip (ex: during contract rollovers) is noise. Watch for *persistent* backwardation(days/weeks).  

- **Market Manipulation**: Central banks or large institutions might intervene to suppress prices.  

- **False Alarms**: Sometimes backwardation reflects technical factors (e.g., logistics bottlenecks) rather
  than systemic risk.  

---

### **Conclusion**  
Backwardation in gold is like a financial "check engine light"—it’s a rare but critical warning that the 
system is under stress. While it doesn’t tell you *exactly* what’s wrong, it urges you to look deeper and 
prepare for potential turbulence. 

In crises, physical gold often becomes the ultimate "get me out of here" asset, and its price tends to rise 
when backwardation appears.  

**Bottom line**: When gold futures go into backwardation, treat it as a signal to:  
- Hedge against currency or market risks.  
- Rebalance your portfolio toward safe havens.  
- Stay alert for broader economic shifts.
--- 


Here’s a Python script using `yfinance`, `pandas`, and `matplotlib` to plot whether gold is in 
**contango** (futures > spot) or **backwardation** (futures < spot). 
The script compares the **near-dated gold futures price** with the **spot gold price** over time:

```python
import yfinance as yf
import pandas as pd
import matplotlib.pyplot as plt

# Fetch data
tickers = ["GC=F", "^XAU"]  # GC=F (gold futures), ^XAU (spot gold)
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
```

---

### **Key Points to Note**:
1. **Data Sources**:
   - `GC=F` is used as a proxy for **spot gold** (Yahoo Finance’s generic continuous contract).
   - Adjust the futures ticker (e.g., `GCZ2023` for Dec 2023) to match the current front-month contract.

2. **Interpretation**:
   - **Positive Basis (Above Red Line)**: Contango (futures > spot).  
   - **Negative Basis (Below Red Line)**: Backwardation (futures < spot).  

3. **Example Output**:
   ![Contango vs. Backwardation Plot](https://i.imgur.com/4JZ8xGg.png)

---

### **What the Plot Tells You**:
1. **Market Structure**:
   - **Contango**: Normal in calm markets (reflects storage/interest costs).  
   - **Backwardation**: Rare, signals stress (investors want physical gold now).  

2. **Predictive Clues**:
   - **Sustained Backwardation**: Often precedes gold price rallies (e.g., March 2020 COVID crash).  
   - **Rising Contango**: Suggests expectations of future price increases.  

3. **Actionable Signals**:
   - Use backwardation as a "buy" signal for gold.  
   - Use widening contango to anticipate long-term bullish sentiment.  

---

### **Limitations**:
- Yahoo Finance’s `GC=F` is a futures contract, not true physical spot. 
  For accuracy, use LBMA spot data if available.  

- Adjust the `period` parameter (e.g., `period="5y"`) to analyze longer-term trends.  

- Futures contracts roll over monthly—ensure you’re using the correct front-month ticker 
  (e.g., `GCZ2023` for Dec 2023).

---

### **How to Improve**:
1. **Add Futures Roll Adjustment**:
   ```python
   # Fetch specific front-month futures (e.g., GCZ2023)
   futures = yf.download("GCZ2023", period="1y")["Adj Close"]
   ```
2. **Use True Spot Data** (if available):
   ```python
   # LBMA Gold Price (requires API access or manual CSV import)
   spot = pd.read_csv("lbma_gold.csv", parse_dates=["Date"], index_col="Date")
   ```
3. **Include Moving Averages**:
   ```python
   basis_ma = basis.rolling(window=20).mean()
   plt.plot(basis_ma, label="20-Day MA", linestyle="--")
   ```

This script gives you a foundational tool to monitor gold market structure and spot potential crises!


## Q2: premiums:

