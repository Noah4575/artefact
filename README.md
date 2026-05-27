# Artefact

## Overview

This repository contains the Artefact project. This README provides general setup and run instructions so you can get the project working locally.

## Prerequisites

- Git
- Python 3.13.1
- pip
- Docker Desktop
- Ollama

## Setup

1. Clone the repository or open it in your editor.
   ```powershell
   git clone https://github.com/Noah4575/artefact.git
   cd artefact
   ```

2. Install dependencies.
     ```powershell
     python -m venv .venv
     source .venv/bin/activate   # macOS/Linux
     .\.venv\Scripts\activate  # Windows
     pip install -r requirements.txt
     ```
## Running the synthetic data notebook
Please install OLLama and pull the model : 
```powershell
ollama pull phi4-mini
```

## Running the Project
Please run Docker Desktop :
# Generate a secret key (PowerShell)
    
    $KEY = [Convert]::ToBase64String((1..42 | ForEach-Object { Get-Random -Maximum 256 }))

    # Start Superset with your dbt project folder mounted
    docker run -d -p 8088:8088 `
    --name superset `
    -e "SUPERSET_SECRET_KEY=$KEY" `
    -v "C:\path\to\your\air_cote_divoire:/dbt" `
    apache/superset:latest
    

Then initialize Superset :
    
    docker exec -it superset superset fab create-admin `
    --username admin --firstname Admin --lastname Admin `
    --email your@email.com --password admin

    docker exec -it superset superset db upgrade
    docker exec -it superset superset init
    

Install DuckDB driver in the container : 
    
    docker exec -it --user root superset /app/.venv/bin/python -m ensurepip
    docker exec -it --user root superset /app/.venv/bin/python -m pip install duckdb-engine duckdb
    docker restart superset
    

Please go into the air_cote_divoire folder:
  ```powershell
  cd air_cote_divoire
  ```
Then run the dbt pipeline : 
  ```powershell
  dbt seed
  dbt parse
  dbt run
  dbt test
  ```

### Launch the Dashboard
Start superset if not already running:
 ```powershell
 docker start superset
 ```
Open http://localhost:8088 and log in with the admin credentials you set up.
Connect to DuckDB
Go to Settings → Database Connections → + Database, select Other, and enter:
duckdb:////dbt/dev.duckdb?access_mode=read_only