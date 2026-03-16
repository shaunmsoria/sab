# Supervised Arbitrage Bot (SAB)
![Supervised Arbitrage Bot v1.0](https://github.com/shaunmsoria/sab/blob/main/bot_supervisor/SAB.png "Example of SAB running in the backend")


Overview

Supervised Arbitrage Bot (SAB) is a high-performance arbitrage monitoring and execution system designed to detect and act on profitable swap opportunities across decentralised exchanges.

The system listens to real-time swap events from Uniswap, Sushiswap, and PancakeSwap V3, processes liquidity updates, and evaluates potential arbitrage trades across liquidity pools.

SAB was built with a strong focus on resilience, performance optimisation, and efficient data processing, enabling the system to operate continuously while processing high-frequency blockchain events.


Key Features

- Real-time event processing from multiple decentralised exchanges
- Automated liquidity tracking across hundreds of thousands of pools
- Profitability analysis for swap opportunities
- Optimised infrastructure designed to run 24/7 with minimal computational cost
- Fault-tolerant architecture designed to handle malformed or unexpected event data


Engineering Challenges

1) Reliable Event Processing

    The first challenge was designing a system capable of reliably processing blockchain events while maintaining accurate liquidity data.
    DEX protocols emit multiple event types including: Swap, Mint, Burn...
    The system must correctly isolate swap events while ignoring irrelevant events within the same stream.
    Additional complexity arises from:

    - inconsistent token naming conventions
    - special characters in token symbols
    - malformed or unexpected event payloads

    To address these challenges, SAB was designed with defensive parsing, validation layers, and fault-tolerant pipelines, ensuring the system remains stable even when encountering unexpected data.


2) 24/7 Operation with Minimal Computational Cost

    Arbitrage opportunities exist for only short time windows, meaning the system must operate continuously to avoid missing profitable trades.

    However, querying DEX liquidity and pricing data can become computationally expensive.
    The challenge was amplified by infrastructure limitations from providers such as:

    - Alchemy
    - Infura

    Their monthly compute unit allocations were reduced from 300M CU to 30M CU, forcing significant optimisation.
    Several strategies were implemented:

    - selective liquidity updates
    - reduced RPC queries
    - caching strategies
    - trading thresholds to ignore low-value swaps unlikely to produce profit

    These optimisations significantly reduced compute consumption while maintaining effective arbitrage detection.


3) Scaling to 300k+ Liquidity Pools

    Uniswap V3 currently supports 300,000+ liquidity pools, representing a large surface area for potential arbitrage.

    Supporting this scale required careful database design to handle:

    - frequent read/write operations
    - concurrent event updates
    - liquidity recalculations

    The system was designed to maintain performance while continuously updating pool liquidity data and evaluating arbitrage opportunities.


Architecture Goals

SAB was designed with several core architectural principles:

- Resilience – handle malformed data without crashing
- Efficiency – minimise compute usage and external queries
- Scalability – support hundreds of thousands of pools
- Observability – monitor arbitrage opportunities and system behaviour


Future Roadmap (SAB Project)

Next development steps include:

- Support for Uniswap V2 and Uniswap V4
- A monitoring dashboard built with Phoenix LiveView
- Real-time visualisation of liquidity pools and profitable trades
- Multi-hop arbitrage strategies across multiple liquidity pools


Security Notice

All API keys shown in .env and .envrc files are for demonstration purposes only.