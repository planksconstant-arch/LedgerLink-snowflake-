# Contributing to LedgerLink

Thank you for your interest in contributing! This project was originally built for the Snowflake CoCo CLI Hackathon. 

## How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Setup
- See `README.md` for running the SQL scripts to initialize the Snowflake database.
- Use `.env.example` as a template for connecting to Snowflake locally.
- `streamlit_app/app.py` can be run locally using `streamlit run`. If no Snowflake connection is present, it will gracefully fall back to mock data for UI testing.
