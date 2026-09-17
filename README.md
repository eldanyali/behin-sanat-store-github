# Behin Sanat Radin Zangan Building Services Equipment Store

A web-based platform for showcasing and selling water, gas, and mechanical building services equipment, developed with Python, Flask, and SQLite.

This project was redesigned and localized as an internship project. It includes a Persian user interface, right-to-left layout, responsive design, product management, a shopping cart, a wishlist, and order placement.

## Features

- Browse products and building services equipment categories
- View a dedicated details page for each product
- User registration and login
- Shopping cart with automatic total calculation
- Wishlist management
- Order placement and user order history
- Administrator panel for adding, editing, and deleting products
- Administrator access to customer orders
- Persian right-to-left user interface
- Responsive design for desktop, tablet, and mobile devices
- SQLite database with no separate database server required

## Technologies Used

- Python 3.12
- Flask 2.3.3
- SQLite
- HTML5
- CSS3
- Bootstrap
- JavaScript
- Vazirmatn font

## Project Structure

```text
behin-sanat-store/
├── app.py
├── init_db.py
├── requirements.txt
├── LICENSE
├── README.md
├── static/
│   ├── css/
│   ├── images/
│   ├── js/
│   └── uploads/
└── templates/
```

The `database.db` file is created after running `init_db.py` and should not be committed to a public repository if it contains personal data.

## Setup on Windows 11

First, clone the repository and open the project directory:

```powershell
git clone https://github.com/eldanyali/behin-sanat-store-github
Set-Location behin-sanat-store
```

Create a virtual environment:

```powershell
py -3.12 -m venv .venv
```

Install the dependencies:

```powershell
.\.venv\Scripts\python.exe -m pip install --timeout 120 --retries 5 -r requirements.txt
```

Initialize the sample database:

```powershell
.\.venv\Scripts\python.exe init_db.py
```

Run the application:

```powershell
.\.venv\Scripts\python.exe app.py
```

Then open the following address in your browser:

```text
http://127.0.0.1:5000
```

```markdown
## Demo Administrator Account

Administrator credentials are not included in this public repository. Contact the project owner for authorized demonstration access.
To set the secret key in PowerShell, use the following command:

```powershell
$env:SECRET_KEY = "a-long-random-secret-key"
```

## Project Health Check

Place `final_audit.ps1` in the project root and run it with the following command:

```powershell
powershell -ExecutionPolicy Bypass -File .\final_audit.ps1
```

The audit results are saved to `final-audit.txt`.

## Demo Notes

- Product prices are sample values and do not represent current market prices.
- Real online payment processing has not been implemented.
- This project was created for educational and internship presentation purposes. Additional security review is required before production use.
- A production version should include secure password hashing, CSRF protection, and production-ready deployment settings.

## Developer

Persian interface design, localization, user experience redesign, and development of the building services edition:

**Elaheh**

Internship project title:

**Design and Implementation of a Web-Based Platform for Showcasing and Selling Building Services Equipment for Behin Sanat Radin Zangan Company**

## Original Source and License

This project is based on the following open-source repository and has been extensively redesigned and localized for the building services equipment industry:

[lovnishverma/nielitecommerece](https://github.com/lovnishverma/nielitecommerece)

The original repository was released under the MIT License. In accordance with the license terms, the `LICENSE` file and the original author's copyright notice must remain in the published version.
