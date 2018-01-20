# mql-csv-export
Contains scripts/experts for pre-rocessing and exporting data from metatrader platform.

## Usage

Copy over experts from Experts folder to MetaTrader's Experts folder and compile. Then, to create the actual export, use Strategy Tester with the given Expert script selected and choosen timeframe and timerange.

### Result

Exported CSV will be placed in `[your user folder]\AppData\Roaming\MetaQuotes\Terminal\[ID Folder]\tester\files`


### Implemented exporters

#### OHCLT train data.mq4

calculates relative difference between consecutive OHLC bars and puts them in rows for each data tick.
Can produce more than a single value per line (controllable in script).
Attaches times alongside each row to give learning network a bit more data about data context.
All values are normalized into [-1;+1] range.
