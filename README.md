# Artefact

## Overview

This repository contains the Artefact project. This README provides general setup and run instructions so you can get the project working locally.

## Prerequisites

- Git
- A compatible runtime for the project (for example, Node.js, Python, .NET, or another language/runtime used by the repository)
- The appropriate package manager for the project (for example, npm/yarn, pip, dotnet)

## Setup

1. Clone the repository or open it in your editor.

   ```bash
   git clone <repository-url>
   cd Artefact
   ```

2. Install dependencies.
     ```bash
     python -m venv .venv
     source .venv/bin/activate   # macOS/Linux
     .\.venv\Scripts\activate  # Windows
     pip install -r requirements.txt
     ```

## Running the Project
Please pull the Docker instance
Please go into the air_cote_divoire folder:
  ```bash
  cd air_cote_divoire
  ```
Then run dbt tests : 
  ```bash
  dbt parse
  dbt test
  dbt run
  ```

Then go back