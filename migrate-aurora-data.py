#!/usr/bin/env python3
"""
Data migration script from Aurora Serverless to new Aurora cluster
"""
import pymysql
import os
import sys

# Old Aurora Serverless connection
OLD_DB_HOST = 'ecogrid-db.ckbygg2eq2ic.us-east-1.rds.amazonaws.com'
OLD_DB_USER = 'admin'
OLD_DB_PASSWORD = 'password'
OLD_DB_NAME = 'ecogrid'

# New Aurora cluster connection (update after cluster creation)
NEW_DB_HOST = os.environ.get('NEW_DB_HOST', 'ecogrid-aurora-cluster.cluster-xxxxxxxxx.us-east-1.rds.amazonaws.com')
NEW_DB_USER = 'admin'
NEW_DB_PASSWORD = 'EcoGrid2025!'
NEW_DB_NAME = 'ecogrid'

def connect_to_db(host, user, password, database):
    """Create database connection"""
    try:
        return pymysql.connect(
            host=host,
            user=user,
            password=password,
            database=database,
            charset='utf8mb4'
        )
    except Exception as e:
        print(f"Connection error to {host}: {e}")
        return None

def create_tables_in_new_db(new_conn):
    """Create tables in new Aurora cluster"""
    cursor = new_conn.cursor()
    
    # Create users table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) NOT NULL,
            password VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Create volunteers table (if exists)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS volunteers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL,
            phone VARCHAR(20),
            interests VARCHAR(100),
            availability TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Create new customer_inquiries table for Join the Community form
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS customer_inquiries (
            id INT AUTO_INCREMENT PRIMARY KEY,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            email VARCHAR(100) NOT NULL,
            phone VARCHAR(20) NOT NULL,
            address TEXT NOT NULL,
            current_provider VARCHAR(100),
            monthly_bill VARCHAR(50),
            estimated_savings DECIMAL(10,2),
            status VARCHAR(20) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_created_at (created_at)
        )
    """)
    
    new_conn.commit()
    print("Tables created successfully in new Aurora cluster")

def migrate_data(old_conn, new_conn):
    """Migrate data from old to new database"""
    old_cursor = old_conn.cursor()
    new_cursor = new_conn.cursor()
    
    # Migrate users table
    try:
        old_cursor.execute("SELECT * FROM users")
        users = old_cursor.fetchall()
        
        for user in users:
            new_cursor.execute("""
                INSERT IGNORE INTO users (id, username, email, password, created_at)
                VALUES (%s, %s, %s, %s, %s)
            """, user)
        
        print(f"Migrated {len(users)} users")
    except Exception as e:
        print(f"Error migrating users: {e}")
    
    # Migrate volunteers table if exists
    try:
        old_cursor.execute("SELECT * FROM volunteers")
        volunteers = old_cursor.fetchall()
        
        for volunteer in volunteers:
            new_cursor.execute("""
                INSERT IGNORE INTO volunteers (id, name, email, phone, interests, availability, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, volunteer)
        
        print(f"Migrated {len(volunteers)} volunteers")
    except Exception as e:
        print(f"Error migrating volunteers (table may not exist): {e}")
    
    new_conn.commit()

def main():
    print("Starting Aurora data migration...")
    
    if len(sys.argv) > 1:
        global NEW_DB_HOST
        NEW_DB_HOST = sys.argv[1]
        print(f"Using new database host: {NEW_DB_HOST}")
    else:
        print("Usage: python migrate-aurora-data.py <new-aurora-endpoint>")
        print("Example: python migrate-aurora-data.py ecogrid-aurora-cluster.cluster-abc123.us-east-1.rds.amazonaws.com")
        return
    
    # Connect to old database
    print("Connecting to old Aurora Serverless...")
    old_conn = connect_to_db(OLD_DB_HOST, OLD_DB_USER, OLD_DB_PASSWORD, OLD_DB_NAME)
    if not old_conn:
        print("Failed to connect to old database")
        return
    
    # Connect to new database
    print("Connecting to new Aurora cluster...")
    new_conn = connect_to_db(NEW_DB_HOST, NEW_DB_USER, NEW_DB_PASSWORD, NEW_DB_NAME)
    if not new_conn:
        print("Failed to connect to new database")
        return
    
    # Create tables in new database
    create_tables_in_new_db(new_conn)
    
    # Migrate data
    migrate_data(old_conn, new_conn)
    
    # Close connections
    old_conn.close()
    new_conn.close()
    
    print("Migration completed successfully!")
    print(f"New database endpoint: {NEW_DB_HOST}")
    print("Update your application configuration to use the new endpoint")

if __name__ == "__main__":
    main()
