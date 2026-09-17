"""Create a clean demonstration database for Behin Sanat Store.

Run from the project root:
    python init_db.py

The script never overwrites an existing database unless --force is supplied.
With --force, it creates a timestamped backup before rebuilding the database.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent
DATABASE_PATH = PROJECT_ROOT / "database.db"
UPLOADS_PATH = PROJECT_ROOT / "static" / "uploads"


CATEGORIES = [
    (1, "تأسیسات آب"),
    (2, "تأسیسات گاز"),
    (3, "تجهیزات مکانیکی"),
    (4, "لوله و اتصالات"),
]


PRODUCTS = [
    (
        1,
        "پمپ آب سانتریفیوژ صنعتی",
        12_500_000,
        "پمپ سانتریفیوژ مناسب انتقال و تقویت فشار آب در پروژه های ساختمانی و تأسیساتی.",
        "ausu.jpg",
        8,
        1,
    ),
    (
        2,
        "شیر توپی برنجی",
        780_000,
        "شیر توپی برنجی مناسب کنترل جریان آب در شبکه لوله کشی ساختمان.",
        "download.jpeg",
        25,
        1,
    ),
    (
        3,
        "رگلاتور فشار گاز",
        2_800_000,
        "رگلاتور کنترل فشار برای استفاده در شبکه گاز رسانی ساختمان.",
        "tws.jpeg",
        12,
        2,
    ),
    (
        4,
        "لوله پنج لایه",
        185_000,
        "لوله پنج لایه مناسب اجرای آب سرد، آب گرم و تأسیسات گرمایشی ساختمان.",
        "s25_samsung.jpg",
        50,
        4,
    ),
    (
        5,
        "کلکتور گرمایش از کف",
        4_650_000,
        "کلکتور مناسب توزیع یکنواخت جریان در سامانه گرمایش از کف.",
        "61A3yfijZ7L.jpg",
        10,
        3,
    ),
    (
        6,
        "شیر فلکه کشویی",
        3_250_000,
        "شیر فلکه کشویی صنعتی برای قطع و وصل جریان در خطوط لوله.",
        "oneplus.jpg",
        14,
        1,
    ),
    (
        7,
        "اتصالات پلی اتیلن",
        650_000,
        "مجموعه اتصالات پلی اتیلن مناسب اجرای شبکه های آب رسانی.",
        "iphone_14_pro_max.jpg",
        30,
        4,
    ),
    (
        8,
        "پکیج دیواری چگالشی",
        38_500_000,
        "پکیج دیواری برای تأمین آب گرم و گرمایش واحدهای ساختمانی.",
        "tv.jpg",
        6,
        3,
    ),
    (
        9,
        "منبع تحت فشار",
        7_900_000,
        "منبع تحت فشار مناسب تثبیت فشار و کاهش دفعات روشن شدن پمپ آب.",
        "noise.jpg",
        5,
        3,
    ),
]


def md5_hash(value: str) -> str:
    """Match the password format currently used by app.py."""

    return hashlib.md5(value.encode("utf-8")).hexdigest()


def backup_existing_database() -> Path:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = PROJECT_ROOT / f"database-private-backup-{timestamp}.db"
    shutil.copy2(DATABASE_PATH, backup_path)
    return backup_path


def create_database(force: bool = False) -> None:
    if DATABASE_PATH.exists():
        if not force:
            raise SystemExit(
                "database.db already exists. Nothing was changed. "
                "Use --force only when you intentionally want a clean database."
            )

        backup_path = backup_existing_database()
        print(f"Backup created: {backup_path.name}")
        DATABASE_PATH.unlink()

    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute("PRAGMA foreign_keys = ON")

        connection.executescript(
            """
            CREATE TABLE users (
                userId INTEGER PRIMARY KEY,
                password TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                firstName TEXT,
                lastName TEXT,
                address1 TEXT,
                address2 TEXT,
                zipcode TEXT,
                city TEXT,
                state TEXT,
                country TEXT,
                phone TEXT
            );

            CREATE TABLE categories (
                categoryId INTEGER PRIMARY KEY,
                name TEXT NOT NULL
            );

            CREATE TABLE products (
                productId INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                price REAL NOT NULL,
                description TEXT,
                image TEXT NOT NULL DEFAULT 'product-default.png',
                stock INTEGER NOT NULL DEFAULT 0,
                categoryId INTEGER NOT NULL,
                FOREIGN KEY (categoryId) REFERENCES categories(categoryId)
            );

            CREATE TABLE kart (
                userId INTEGER NOT NULL,
                productId INTEGER NOT NULL,
                FOREIGN KEY (userId) REFERENCES users(userId),
                FOREIGN KEY (productId) REFERENCES products(productId)
            );

            CREATE TABLE wishlist (
                wishlistId INTEGER PRIMARY KEY AUTOINCREMENT,
                userId INTEGER NOT NULL,
                productId INTEGER NOT NULL,
                UNIQUE (userId, productId),
                FOREIGN KEY (userId) REFERENCES users(userId),
                FOREIGN KEY (productId) REFERENCES products(productId)
            );

            CREATE TABLE allorders (
                orderId INTEGER PRIMARY KEY AUTOINCREMENT,
                userId INTEGER NOT NULL,
                productId INTEGER NOT NULL,
                quantity INTEGER NOT NULL,
                total_price REAL NOT NULL,
                order_date TEXT NOT NULL,
                FOREIGN KEY (userId) REFERENCES users(userId),
                FOREIGN KEY (productId) REFERENCES products(productId)
            );
            """
        )

        connection.executemany(
            "INSERT INTO categories (categoryId, name) VALUES (?, ?)",
            CATEGORIES,
        )

        connection.executemany(
            """
            INSERT INTO products
                (productId, name, price, description, image, stock, categoryId)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            PRODUCTS,
        )

        connection.execute(
            """
            INSERT INTO users
                (userId, password, email, firstName, lastName, address1,
                 address2, zipcode, city, state, country, phone)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                1,
                md5_hash("admin@nielit.gov.in"),
                "admin@nielit.gov.in",
                "ADMIN",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
            ),
        )

        connection.commit()

        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise RuntimeError(f"SQLite integrity check failed: {integrity}")

    print(f"Clean demo database created: {DATABASE_PATH}")
    print("Admin email: admin@nielit.gov.in")
    print("Admin password: admin@nielit.gov.in")

    missing_images = [
        image_name
        for *_, image_name, _stock, _category_id in PRODUCTS
        if not (UPLOADS_PATH / image_name).exists()
    ]
    if missing_images:
        print("Warning: these product images were not found in static/uploads:")
        for image_name in missing_images:
            print(f"  - {image_name}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a clean SQLite demonstration database."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Back up and replace an existing database.db file.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    create_database(force=arguments.force)
