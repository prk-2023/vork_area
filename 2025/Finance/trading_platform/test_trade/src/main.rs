use reqwest::blocking::Client;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct TwseResponse {
    // We'll parse the minimal fields for example
    #[serde(rename = "msgArray")]
    msg_array: Vec<TwseStock>,
}

#[derive(Debug, Deserialize)]
struct TwseStock {
    #[serde(rename = "c")]
    code: String,
    #[serde(rename = "n")]
    name: String,
    #[serde(rename = "z")]
    price: String,
}

fn fetch_live_quote(stock_code: &str) -> Result<TwseStock, Box<dyn std::error::Error>> {
    let url = format!(
        "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_{}.tw&json=1&delay=0",
        stock_code
    );

    let client = Client::new();
    let resp = client.get(&url).send()?.json::<TwseResponse>()?;

    if let Some(stock) = resp.msg_array.into_iter().next() {
        Ok(stock)
    } else {
        Err("No stock data found".into())
    }
}

fn main() {
    //let stock_code = "2330"; // TSMC example
    let stock_code = "8033"; // Thunder tiger corp ( taiwan drones )
    match fetch_live_quote(stock_code) {
        Ok(stock) => println!("{} {} {}", stock.code, stock.name, stock.price),
        Err(e) => eprintln!("Error: {}", e),
    }
}
