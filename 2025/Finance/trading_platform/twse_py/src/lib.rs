use pyo3::prelude::*;
use reqwest::blocking::Client;
use serde::Deserialize;

#[derive(Deserialize)]
struct TwseResponse {
    #[serde(rename = "msgArray")]
    msg_array: Vec<TwseStock>,
}

#[derive(Deserialize)]
struct TwseStock {
    #[serde(rename = "c")]
    code: String,
    #[serde(rename = "n")]
    name: String,
    #[serde(rename = "z")]
    price: String,
}

/// Fetch latest stock price from TWSE
#[pyfunction]
fn fetch_twse_stock(stock_code: &str) -> PyResult<Option<(String, String, f64)>> {
    let url = format!(
        "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_{}.tw&json=1&delay=0",
        stock_code
    );
    let client = Client::new();

    let resp = client
        .get(&url)
        .send()
        .map_err(|e| pyo3::exceptions::PyIOError::new_err(e.to_string()))?
        .json::<TwseResponse>()
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e.to_string()))?;

    if let Some(stock) = resp.msg_array.into_iter().next() {
        let price = stock.price.parse::<f64>().unwrap_or(0.0);
        Ok(Some((stock.code, stock.name, price)))
    } else {
        Ok(None)
    }
}

#[pymodule]
fn twse_py(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(fetch_twse_stock, m)?)?;
    Ok(())
}
