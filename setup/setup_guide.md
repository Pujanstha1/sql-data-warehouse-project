# Project Setup Guide

This guide covers everything needed to start the **Data Warehouse and Analytics Project**: the tools, the repository, the folder structure and the database. The project was built on **Windows** using **Microsoft SQL Server** and **SQL Server Management Studio (SSMS)**, with **VS Code**, **draw.io**, **Git Bash** and **GitHub** for documentation and version control.

---

## 1. Tools used

| Tool | Purpose |
|---|---|
| **Microsoft SQL Server (Express)** | Database engine that hosts the data warehouse |
| **SQL Server Management Studio (SSMS)** | Client for writing and running T-SQL, and browsing the database |
| **Visual Studio Code** | Editing SQL scripts and Markdown documentation (README, walkthrough) |
| **draw.io (diagrams.net)** | Architecture, data flow, integration and data model diagrams |
| **Git (Git Bash)** | Local version control from the command line |
| **GitHub** | Remote repository and public portfolio |
| **Notion** (optional) | Project plan: epics, tasks and progress tracking |

**Environment:** Windows 10/11 · SQL Server (Express edition) · SSMS · VS Code · Git Bash

---

## 2. Install the tools

### 2.1 SQL Server Express

1. Download **SQL Server Express** from Microsoft's SQL Server downloads page.
2. Run the installer and choose the **Basic** installation type.
3. Accept the licence terms and the default install location.
4. When the install finishes, note the connection string shown (typically `localhost\SQLEXPRESS`).

### 2.2 SQL Server Management Studio (SSMS)

1. Download the latest **SSMS** from Microsoft.
2. Run the installer and complete the setup. A restart may be required.

### 2.3 Visual Studio Code

1. Download VS Code from the official site and install it.
2. Recommended extensions:
   - **SQL Server (mssql)**: optional, for running queries inside VS Code
   - **Markdown All in One** or the built-in Markdown preview: for editing the README and docs
   - **draw.io Integration**: optional, to edit `.drawio` files inside VS Code

### 2.4 draw.io

Use the web app at diagrams.net, the desktop app, or the VS Code extension. Save diagram sources as `.drawio` and export images as `.png` or `.jpg` into the `docs/` folder.

### 2.5 Git and Git Bash

1. Download **Git for Windows**, which includes **Git Bash**.
2. Accept the defaults during installation.
3. Open **Git Bash** and set your identity (one-time):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git --version
```

### 2.6 GitHub account

Create a free account at github.com if you don't already have one. Use the same email you set in Git so commits are linked to your profile.

---

## 3. Verify the SQL Server connection

1. Open **SSMS**.
2. In the **Connect to Server** dialog:
   - **Server type:** Database Engine
   - **Server name:** `localhost\SQLEXPRESS` (or `.\SQLEXPRESS`)
   - **Authentication:** Windows Authentication
3. If you see a certificate or encryption error, tick **Trust server certificate** and connect again (acceptable for a local development instance).
4. Click **Connect**. You should see the server in **Object Explorer**.

---

## 4. Create the GitHub repository

1. On GitHub, select **New repository**.
2. Settings:
   - **Name:** `sql-data-warehouse-project`
   - **Description:** *Data warehouse built with SQL Server using the Medallion architecture (Bronze, Silver, Gold)*
   - **Visibility:** Public
   - **Initialise with:** a README
   - **License:** MIT
3. Select **Create repository**.

### Clone it locally (Git Bash)

```bash
cd /c/Projects            # or any folder you prefer
git clone https://github.com/<your-username>/sql-data-warehouse-project.git
cd sql-data-warehouse-project
code .                    # opens the project in VS Code
```

---

## 5. Create the folder structure

From the repository root in Git Bash:

```bash
mkdir -p setup datasets/source_crm datasets/source_erp docs \
         scripts/bronze scripts/silver scripts/gold tests
```

Git does not track empty folders, so add a placeholder file in each one that has no content yet:

```bash
touch datasets/source_crm/.gitkeep datasets/source_erp/.gitkeep \
      scripts/bronze/.gitkeep scripts/silver/.gitkeep scripts/gold/.gitkeep \
      tests/.gitkeep docs/.gitkeep
```

Target structure:

```
sql-data-warehouse-project/
├── setup/                   # this guide
├── datasets/
│   ├── source_crm/          # cust_info.csv, prd_info.csv, sales_details.csv
│   └── source_erp/          # CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv
├── docs/                    # diagrams, data catalog, walkthrough
├── scripts/
│   ├── init_database.sql
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── tests/
├── LICENSE
└── README.md
```

Save this file as `setup/setup_guide.md`.

---

## 6. Add the source data

1. Copy the three CRM files into `datasets/source_crm/` and the three ERP files into `datasets/source_erp/`.
2. For `BULK INSERT`, SQL Server needs to read the files from a location its service account can access. The scripts expect them at:

```
C:\sql\dwh_project\datasets\
├── source_crm\
└── source_erp\
```

Copy the `datasets` folder there, or edit the six file paths in `scripts/bronze/proc_load_bronze.sql` to point to your location.

3. Open each CSV and note the header row, the delimiter and the column order. This matters when you define the Bronze tables.

> **Permissions tip:** if `BULK INSERT` reports that a file cannot be opened, the SQL Server service account probably cannot read that folder. Use a simple path such as `C:\sql\...` and grant read access if needed.

---

## 7. Optional but recommended: project plan and .gitignore

**Project plan.** In Notion (or any tracker), create *Epics* (Requirements, Architecture, Initialisation, Bronze, Silver, Gold) and *Tasks* linked to them. Each layer follows the same pattern: **Analyse → Code → Validate → Document → Commit**.

**.gitignore.** Create a `.gitignore` in the repo root:

```gitignore
# OS and editor files
.DS_Store
Thumbs.db
.vscode/

# SQL Server artefacts (if any are generated locally)
*.bak
*.mdf
*.ldf

# Draw.io backups
*.drawio.bkp
.$*.bkp
```

If you do not want to publish the raw source files, add `datasets/` here too.

---

## 8. Create the database and schemas

1. In SSMS, select **New Query**.
2. Paste the contents of `scripts/init_database.sql` and run it.

```sql
USE master;
GO

-- Drop and recreate the 'DataWarehouse' database if it exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
```

> ⚠️ **Warning:** this script permanently deletes an existing `DataWarehouse` database before recreating it.

3. In **Object Explorer**, right-click **Databases** → **Refresh**. Expand **DataWarehouse → Security → Schemas** and confirm `bronze`, `silver` and `gold` exist.

---

## 9. Make the first commit

From the repository root in Git Bash:

```bash
git status
git add .
git commit -m "Initial project structure, setup guide and database initialisation script"
git push origin main
```

Open the repository on GitHub and confirm the folders and files appear.

### Commit habit used throughout the project

Commit after each completed step with a clear message, for example:

```bash
git add scripts/bronze/
git commit -m "Add Bronze layer DDL and load procedure"
git push
```

---

## 10. Setup checklist

- [ ] SQL Server Express and SSMS installed; connection to `localhost\SQLEXPRESS` works
- [ ] VS Code, draw.io, Git and Git Bash installed
- [ ] Git identity configured
- [ ] GitHub repository created and cloned
- [ ] Folder structure created
- [ ] Source CSV files placed in `datasets/` (and available to SQL Server at the path used by the load script)
- [ ] `init_database.sql` executed: `DataWarehouse` database with `bronze`, `silver`, `gold` schemas
- [ ] First commit pushed to GitHub

**Next:** build the Bronze layer. See the [Project Walkthrough](../docs/project_walkthrough.md).
