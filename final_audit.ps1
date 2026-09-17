[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

try {
    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
} catch {
    Write-Host "Project path was not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

$reportPath = Join-Path $ProjectPath "final-audit.txt"
$lines = [System.Collections.Generic.List[string]]::new()
$passCount = 0
$warningCount = 0
$failureCount = 0

function Add-Line([string]$Text = "") {
    $script:lines.Add($Text)
    Write-Host $Text
}

function Add-Section([string]$Title) {
    Add-Line ""
    Add-Line ("=" * 72)
    Add-Line $Title
    Add-Line ("=" * 72)
}

function Add-Pass([string]$Text) {
    $script:passCount++
    Add-Line "[PASS] $Text"
}

function Add-Warning([string]$Text) {
    $script:warningCount++
    Add-Line "[WARN] $Text"
}

function Add-Failure([string]$Text) {
    $script:failureCount++
    Add-Line "[FAIL] $Text"
}

Add-Line "Behin Sanat Store - Final Audit"
Add-Line "Project: $ProjectPath"
Add-Line "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Line "This audit does not delete or modify project files."

if (-not (Test-Path (Join-Path $ProjectPath "app.py"))) {
    Add-Failure "app.py was not found. Run this script from D:\behin-sanat-store."
    $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
    exit 1
}

Add-Section "1. Required project files"

$requiredPaths = @(
    "app.py",
    "database.db",
    "requirements.txt",
    "templates",
    "templates\home.html",
    "templates\productDescription.html",
    "templates\cart.html",
    "templates\wishlist.html",
    "templates\user_orders.html",
    "static",
    "static\css\persian.css",
    "static\images\gtnielit logo.png",
    "static\images\product-default.png",
    "static\uploads\product-default.png"
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $ProjectPath $relativePath
    if (Test-Path -LiteralPath $fullPath) {
        Add-Pass $relativePath
    } else {
        Add-Failure "Missing: $relativePath"
    }
}

Add-Section "2. Product image fix"

$productTemplate = Join-Path $ProjectPath "templates\productDescription.html"
$persianCss = Join-Path $ProjectPath "static\css\persian.css"

if (Test-Path -LiteralPath $productTemplate) {
    if (Select-String -LiteralPath $productTemplate -Pattern "product-detail-image" -Quiet) {
        Add-Pass "The product template uses product-detail-image."
    } else {
        Add-Failure "productDescription.html is still the old template."
    }
}

if (Test-Path -LiteralPath $persianCss) {
    if (Select-String -LiteralPath $persianCss -Pattern "FINAL-PRODUCT-IMAGE-FIX" -Quiet) {
        Add-Pass "The final product image size fix exists in persian.css."
    } else {
        Add-Warning "FINAL-PRODUCT-IMAGE-FIX was not found in persian.css."
    }
}

Add-Section "3. Files that should not be committed to GitHub"

$unwantedItems = @()
$unwantedItems += Get-ChildItem -LiteralPath $ProjectPath -Directory -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @(".venv", "venv", "__pycache__", ".pytest_cache", ".idea", ".vscode", "backup_before_farsi") }
$unwantedItems += Get-ChildItem -LiteralPath $ProjectPath -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".pyc", ".pyo", ".zip") -or $_.Name -eq ".DS_Store" }

if ($unwantedItems.Count -eq 0) {
    Add-Pass "No temporary or virtual-environment files were found."
} else {
    foreach ($item in ($unwantedItems | Sort-Object FullName -Unique)) {
        $relative = $item.FullName.Substring($ProjectPath.Length).TrimStart('\')
        Add-Warning "Do not commit: $relative"
    }
}

$glitchAssets = Join-Path $ProjectPath ".glitch-assets"
if (Test-Path -LiteralPath $glitchAssets) {
    Add-Warning "Delete .glitch-assets before creating the new repository."
}

Add-Section "4. Python and template validation"

$venvPython = Join-Path $ProjectPath ".venv\Scripts\python.exe"
if (Test-Path -LiteralPath $venvPython) {
    $pythonExe = $venvPython
    Add-Pass "Virtual environment Python was found."
} else {
    $pythonExe = "py"
    Add-Warning "The local .venv Python was not found; using the py launcher."
}

$pythonCheck = @'
import os
import re
import sqlite3
import sys
from pathlib import Path

root = Path.cwd()

try:
    compile((root / "app.py").read_text(encoding="utf-8-sig"), "app.py", "exec")
    print("PASS|app.py syntax is valid")
except Exception as exc:
    print(f"FAIL|app.py syntax error: {exc}")

try:
    from jinja2 import Environment
    environment = Environment()
    template_errors = []
    templates = sorted((root / "templates").glob("*.html"))
    for template in templates:
        try:
            environment.parse(template.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            template_errors.append(f"{template.name}: {exc}")
    if template_errors:
        for error in template_errors:
            print(f"FAIL|Jinja template error: {error}")
    else:
        print(f"PASS|All {len(templates)} Jinja templates parsed successfully")
except Exception as exc:
    print(f"FAIL|Jinja validation could not run: {exc}")

try:
    missing = []
    pattern = re.compile(r"filename\s*=\s*['\"]([^'\"]+)['\"]")
    for template in sorted((root / "templates").glob("*.html")):
        text = template.read_text(encoding="utf-8-sig")
        for reference in pattern.findall(text):
            if "+" in reference or "{" in reference or reference.endswith("/"):
                continue
            target = root / "static" / reference
            if not target.exists():
                missing.append(f"{template.name} -> static/{reference}")
    if missing:
        for item in sorted(set(missing)):
            print(f"WARN|Missing static reference: {item}")
    else:
        print("PASS|All literal static references exist")
except Exception as exc:
    print(f"WARN|Static reference validation could not run: {exc}")

database_path = root / "database.db"
try:
    with sqlite3.connect(database_path) as connection:
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        tables = {row[0] for row in connection.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        )}
        expected = {"users", "products", "categories", "kart", "wishlist", "allorders"}
        if integrity == "ok":
            print("PASS|SQLite integrity check returned ok")
        else:
            print(f"FAIL|SQLite integrity check returned: {integrity}")
        missing_tables = sorted(expected - tables)
        if missing_tables:
            print(f"FAIL|Missing database tables: {', '.join(missing_tables)}")
        else:
            print("PASS|Required database tables exist")
        user_count = connection.execute("SELECT COUNT(*) FROM users").fetchone()[0]
        order_count = connection.execute("SELECT COUNT(*) FROM allorders").fetchone()[0]
        print(f"INFO|Database contains {user_count} users and {order_count} orders")
        if user_count > 1 or order_count > 0:
            print("WARN|Sanitize database.db before publishing it publicly")
except Exception as exc:
    print(f"FAIL|Database validation failed: {exc}")

try:
    os.chdir(root)
    sys.path.insert(0, str(root))
    from app import app
    app.config.update(TESTING=True)
    client = app.test_client()

    with sqlite3.connect(database_path) as connection:
        product = connection.execute(
            "SELECT productId, categoryId FROM products ORDER BY productId LIMIT 1"
        ).fetchone()

    public_paths = ["/", "/loginForm", "/registerationForm"]
    if product:
        public_paths.extend([
            f"/productDescription?productId={product[0]}",
            f"/displayCategory?categoryId={product[1]}",
        ])

    route_errors = []
    for path in public_paths:
        response = client.get(path, follow_redirects=False)
        if response.status_code not in (200, 302):
            route_errors.append(f"{path} -> {response.status_code}")

    with client.session_transaction() as session:
        session["email"] = "admin@nielit.gov.in"

    protected_paths = [
        "/cart",
        "/wishlist",
        "/account/orders",
        "/account/profile",
        "/account/profile/edit",
        "/account/profile/changePassword",
        "/admin",
        "/vieworders",
    ]
    for path in protected_paths:
        response = client.get(path, follow_redirects=False)
        if response.status_code not in (200, 302):
            route_errors.append(f"{path} -> {response.status_code}")

    if route_errors:
        for error in route_errors:
            print(f"FAIL|Route failed: {error}")
    else:
        print(f"PASS|{len(public_paths) + len(protected_paths)} safe routes passed smoke testing")
except Exception as exc:
    print(f"FAIL|Route smoke test failed: {type(exc).__name__}: {exc}")
'@

try {
    Push-Location $ProjectPath
    $pythonOutput = $pythonCheck | & $pythonExe - 2>&1
    Pop-Location

    foreach ($entry in $pythonOutput) {
        $text = [string]$entry
        if ($text.StartsWith("PASS|")) {
            Add-Pass $text.Substring(5)
        } elseif ($text.StartsWith("WARN|")) {
            Add-Warning $text.Substring(5)
        } elseif ($text.StartsWith("FAIL|")) {
            Add-Failure $text.Substring(5)
        } else {
            Add-Line "[INFO] $text"
        }
    }
} catch {
    if ((Get-Location).Path -ne $ProjectPath) {
        Pop-Location -ErrorAction SilentlyContinue
    }
    Add-Failure "Python validation failed to start: $($_.Exception.Message)"
}

Add-Section "5. Old branding and publish warnings"

$scanFiles = @()
$scanFiles += Get-ChildItem -LiteralPath (Join-Path $ProjectPath "templates") -Filter "*.html" -File -ErrorAction SilentlyContinue
$scanFiles += Get-ChildItem -LiteralPath (Join-Path $ProjectPath "static") -Include "*.css", "*.js" -File -Recurse -ErrorAction SilentlyContinue
$scanFiles += Get-Item -LiteralPath (Join-Path $ProjectPath "app.py") -ErrorAction SilentlyContinue

$oldPatterns = "NIELIT Logo|NIELITECOM|nielitecommerece|Rs[ ]|₹|Asia/Kolkata"
$oldMatches = $scanFiles | Select-String -Pattern $oldPatterns -AllMatches -ErrorAction SilentlyContinue
if ($oldMatches) {
    foreach ($match in $oldMatches) {
        $relative = $match.Path.Substring($ProjectPath.Length).TrimStart('\')
        Add-Warning "Old text: ${relative}:$($match.LineNumber) -> $($match.Line.Trim())"
    }
} else {
    Add-Pass "No old brand, rupee currency, or India timezone text was found."
}

$appPath = Join-Path $ProjectPath "app.py"
if (Select-String -LiteralPath $appPath -Pattern "your-secret-key-change-this-in-production|development-key-change-before-deployment" -Quiet) {
    Add-Warning "app.py uses a development fallback key. Set SECRET_KEY before public deployment."
}
if (Select-String -LiteralPath $appPath -Pattern "debug=True" -Quiet) {
    Add-Warning "app.py still runs with debug=True. Disable it before public deployment."
}
if (Select-String -LiteralPath $appPath -Pattern "hashlib\.md5" -Quiet) {
    Add-Warning "Passwords still use MD5. This is acceptable only for a local educational demo."
}

Add-Section "6. Repository state"

if (Test-Path -LiteralPath (Join-Path $ProjectPath ".git")) {
    Add-Pass ".git directory exists."
    try {
        Push-Location $ProjectPath
        $remote = git remote -v 2>&1
        $status = git status --short 2>&1
        Pop-Location
        if ($remote) {
            Add-Line "[INFO] Git remotes:"
            foreach ($line in $remote) { Add-Line "       $line" }
        } else {
            Add-Warning "No Git remote is configured."
        }
        if ($status) {
            Add-Line "[INFO] Git changes:"
            foreach ($line in $status) { Add-Line "       $line" }
        } else {
            Add-Pass "Git working tree is clean."
        }
    } catch {
        Add-Warning "Git information could not be read."
    }
} else {
    Add-Warning "This folder is not a Git repository yet. That is fine before the final cleanup."
}

Add-Section "7. Size summary"

$allFiles = Get-ChildItem -LiteralPath $ProjectPath -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "[\\/](\.venv|venv|\.git)[\\/]" }
$totalBytes = ($allFiles | Measure-Object -Property Length -Sum).Sum
if ($null -eq $totalBytes) { $totalBytes = 0 }
Add-Line ("[INFO] Files excluding .venv and .git: {0}" -f $allFiles.Count)
Add-Line ("[INFO] Total size excluding .venv and .git: {0:N2} MB" -f ($totalBytes / 1MB))

$largeFiles = $allFiles | Where-Object { $_.Length -gt 5MB } | Sort-Object Length -Descending
if ($largeFiles) {
    foreach ($file in $largeFiles) {
        $relative = $file.FullName.Substring($ProjectPath.Length).TrimStart('\')
        Add-Warning ("Large file: {0} ({1:N2} MB)" -f $relative, ($file.Length / 1MB))
    }
} else {
    Add-Pass "No file is larger than 5 MB."
}

Add-Section "Summary"
Add-Line "PASS: $passCount"
Add-Line "WARN: $warningCount"
Add-Line "FAIL: $failureCount"

if ($failureCount -eq 0) {
    Add-Line "RESULT: The project has no blocking validation failure. Review warnings before publishing."
} else {
    Add-Line "RESULT: Fix FAIL items before publishing or presenting the project."
}

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-Host ""
Write-Host "Audit report saved to: $reportPath" -ForegroundColor Cyan

if ($failureCount -gt 0) {
    exit 2
}

exit 0
