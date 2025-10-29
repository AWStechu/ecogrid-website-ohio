from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, session
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
import pymysql
import bcrypt
import os
import boto3
import time
from pycognito import Cognito

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-in-production')

# AWS Cognito configuration
COGNITO_USER_POOL_ID = os.environ.get('COGNITO_USER_POOL_ID', 'us-east-1_72Z74NWLb')
COGNITO_CLIENT_ID = os.environ.get('COGNITO_CLIENT_ID', '2no7600re6tbrg5j384hssnbeh')
COGNITO_CLIENT_SECRET = os.environ.get('COGNITO_CLIENT_SECRET', 'b8j29l10koohs94feon2rtn7092m35pvs2evqr9unisso5lvgk1')
COGNITO_REGION = os.environ.get('COGNITO_REGION', 'us-east-1')

# Flask-Login setup
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Database configuration - Always use private Aurora cluster for database auth
DB_HOST = os.environ.get('DB_HOST', 'ecogrid-aurora-private.cluster-ckbygg2eq2ic.us-east-1.rds.amazonaws.com')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'EcoGrid2025!')
DB_NAME = os.environ.get('DB_NAME', 'ecogrid')

# Authentication method - default to database auth
USE_COGNITO = os.environ.get('USE_COGNITO', 'false').lower() == 'true'

@app.route('/health')
def health_check():
    try:
        # Quick database connectivity check
        if DB_HOST:
            connection = pymysql.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                connect_timeout=2
            )
            connection.close()
            db_status = "connected"
        else:
            db_status = "no_db_configured"
    except:
        db_status = "connection_failed"
    
    return jsonify({
        "status": "healthy", 
        "version": "v2.0-database-auth",
        "auth_method": "cognito" if USE_COGNITO else "database",
        "db_host": DB_HOST.split('.')[0] if DB_HOST else "none",
        "db_status": db_status,
        "timestamp": int(time.time())
    })

@app.route('/verify')
def verify_loaderio():
    return render_template('verification.html'), 200, {'Content-Type': 'text/plain'}

@app.route('/loaderio-fcf3883131e364552ab4c6ea54e99ad1.txt')
def loaderio_verification():
    return render_template('verification.html'), 200, {'Content-Type': 'text/plain'}

@app.route('/loaderio-fcf3883131e364552ab4c6ea54e99ad1.html')
def loaderio_verification_html():
    return 'loaderio-fcf3883131e364552ab4c6ea54e99ad1', 200, {'Content-Type': 'text/plain'}

@app.route('/loaderio-fcf3883131e364552ab4c6ea54e99ad1/')
def loaderio_verification_dir():
    return 'loaderio-fcf3883131e364552ab4c6ea54e99ad1', 200, {'Content-Type': 'text/plain'}

class User(UserMixin):
    def __init__(self, id, username, email):
        self.id = id
        self.username = username
        self.email = email

@login_manager.user_loader
def load_user(user_id):
    if not USE_COGNITO:
        # Database authentication
        try:
            connection = get_db_connection()
            if connection:
                cursor = connection.cursor()
                cursor.execute("SELECT id, username, email FROM users WHERE id = %s", (user_id,))
                user_data = cursor.fetchone()
                cursor.close()
                connection.close()
                if user_data:
                    return User(user_data[0], user_data[1], user_data[2])
        except Exception as e:
            print(f"Database user load error: {e}")
        return None
    
    # Cognito authentication
    try:
        cognito = Cognito(COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, 
                         client_secret=COGNITO_CLIENT_SECRET, user_pool_region=COGNITO_REGION, username=user_id)
        user_attrs = cognito.get_user()
        email = next((attr['Value'] for attr in user_attrs.user_attributes if attr['Name'] == 'email'), user_id)
        return User(user_id, user_id, email)
    except:
        return None

def get_db_connection():
    try:
        return pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4'
        )
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def init_database():
    """Initialize database with users table and test data"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Create users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create customer inquiries table for Join the Community form
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
        
        # Create customer billing table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS customer_billing (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT,
                month VARCHAR(20) NOT NULL,
                kwh_used DECIMAL(10,2) NOT NULL,
                rate_per_kwh DECIMAL(5,4) NOT NULL,
                total_amount DECIMAL(10,2) NOT NULL,
                bill_date DATE NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)
        
        # Test users data - credentials removed for security
        test_users = [
            ('admin', 'admin@ecogrid.com', 'admin123'),
            ('demo', 'demo@ecogrid.com', 'demo123'),
            ('test', 'test@ecogrid.com', 'test123'),
            ('admin@ecogrid.com', 'admin@ecogrid.com', 'admin123')
        ]
        
        # Insert test users
        for username, email, password in test_users:
            # Hash password
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
            
            # Insert user (ignore if already exists)
            cursor.execute("""
                INSERT IGNORE INTO users (username, email, password) 
                VALUES (%s, %s, %s)
            """, (username, email, hashed_password))
        
        # Insert sample billing data
        sample_billing = [
            (2, 'January 2025', 850.50, 0.08, 68.04, '2025-01-15'),
            (2, 'February 2025', 920.75, 0.08, 73.66, '2025-02-15'),
            (2, 'March 2025', 780.25, 0.08, 62.42, '2025-03-15'),
            (3, 'January 2025', 1150.00, 0.08, 92.00, '2025-01-15'),
            (3, 'February 2025', 1050.50, 0.08, 84.04, '2025-02-15'),
            (3, 'March 2025', 1200.75, 0.08, 96.06, '2025-03-15'),
            (4, 'January 2025', 650.25, 0.08, 52.02, '2025-01-15'),
            (4, 'February 2025', 720.50, 0.08, 57.64, '2025-02-15'),
            (4, 'March 2025', 680.75, 0.08, 54.46, '2025-03-15'),
        ]
        
        for user_id, month, kwh_used, rate, total, bill_date in sample_billing:
            cursor.execute("""
                INSERT IGNORE INTO customer_billing (user_id, month, kwh_used, rate_per_kwh, total_amount, bill_date)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (user_id, month, kwh_used, rate, total, bill_date))
        
        connection.commit()
        cursor.close()
        connection.close()
        print("Database initialized successfully!")
    except Exception as e:
        print(f"Database initialization error: {e}")

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/projects')
def projects():
    return render_template('projects.html')

@app.route('/join-community')
def join_community():
    return render_template('join-community.html')

@app.route('/volunteer')
def volunteer():
    return redirect(url_for('login'))

@app.route('/customer-login')
def customer_login():
    return render_template('volunteer.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        if not USE_COGNITO:
            # Database authentication
            try:
                connection = get_db_connection()
                if connection:
                    cursor = connection.cursor()
                    cursor.execute("SELECT id, username, email, password FROM users WHERE username = %s OR email = %s", (username, username))
                    user_data = cursor.fetchone()
                    cursor.close()
                    connection.close()
                    
                    if user_data:
                        stored_password = user_data[3]
                        # Check if password is bcrypt hashed or plain text
                        if stored_password.startswith('$2b$'):
                            # Bcrypt hashed password
                            if bcrypt.checkpw(password.encode('utf-8'), stored_password.encode('utf-8')):
                                user = User(user_data[0], user_data[1], user_data[2])
                                login_user(user)
                                return redirect(url_for('dashboard'))
                        else:
                            # Plain text password
                            if password == stored_password:
                                user = User(user_data[0], user_data[1], user_data[2])
                                login_user(user)
                                return redirect(url_for('dashboard'))
                
                return redirect(url_for('login') + '?error=invalid')
            except Exception as e:
                print(f"Database login error: {e}")
                return redirect(url_for('login') + '?error=invalid')
        
        # Cognito authentication
        try:
            cognito = Cognito(COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, 
                             client_secret=COGNITO_CLIENT_SECRET, user_pool_region=COGNITO_REGION,
                             username=username)
            cognito.admin_authenticate(password=password)
            
            # Get user attributes from Cognito
            user_attrs = cognito.get_user()
            email = getattr(user_attrs, 'email', username)  # Use getattr to safely get email
            
            # Create user object for Flask-Login
            user = User(username, username, email)
            login_user(user)
            return redirect(url_for('dashboard'))
            
        except Exception as e:
            print(f"Login error: {e}")  # Debug line
            return redirect(url_for('login') + '?error=invalid')
    
    return render_template('volunteer.html')

@app.route('/dashboard')
@login_required
def dashboard():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Get user's billing data
        cursor.execute("""
            SELECT month, kwh_used, rate_per_kwh, total_amount, bill_date 
            FROM customer_billing 
            WHERE user_id = %s 
            ORDER BY bill_date DESC
        """, (current_user.id,))
        billing_data = cursor.fetchall()
        
        # Calculate totals
        total_kwh = sum([bill[1] for bill in billing_data]) if billing_data else 0
        total_amount = sum([bill[3] for bill in billing_data]) if billing_data else 0
        avg_monthly_usage = total_kwh / len(billing_data) if billing_data else 0
        
        cursor.close()
        connection.close()
        
        return render_template('dashboard.html', 
                             billing_data=billing_data,
                             total_kwh=total_kwh,
                             total_amount=total_amount,
                             avg_monthly_usage=avg_monthly_usage)
    except Exception as e:
        print(f"Dashboard error: {e}")
        return render_template('dashboard.html', 
                             billing_data=[],
                             total_kwh=0,
                             total_amount=0,
                             avg_monthly_usage=0)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('home'))

@app.route('/api/join-community', methods=['POST'])
def submit_join_community():
    try:
        data = request.json
        
        # Calculate potential savings based on monthly bill
        bill_ranges = {
            'under-50': 25,
            '50-100': 75,
            '100-150': 125,
            '150-200': 175,
            '200-300': 250,
            'over-300': 350
        }
        
        monthly_bill = bill_ranges.get(data.get('monthlyBill', ''), 100)
        # Assume 30% savings with EcoGrid
        annual_savings = int(monthly_bill * 12 * 0.3)
        
        # Store customer inquiry in database
        connection = get_db_connection()
        if connection:
            cursor = connection.cursor()
            cursor.execute("""
                INSERT INTO customer_inquiries 
                (first_name, last_name, email, phone, address, current_provider, monthly_bill, estimated_savings)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                data.get('firstName', ''),
                data.get('lastName', ''),
                data.get('email', ''),
                data.get('phone', ''),
                data.get('address', ''),
                data.get('currentProvider', ''),
                data.get('monthlyBill', ''),
                annual_savings
            ))
            connection.commit()
            cursor.close()
            connection.close()
            print(f"Customer inquiry stored: {data.get('firstName')} {data.get('lastName')} - Potential savings: ${annual_savings}/year")
        else:
            print(f"Database unavailable - Customer inquiry: {data.get('firstName')} {data.get('lastName')} - Potential savings: ${annual_savings}/year")
        
        return jsonify({
            'status': 'success', 
            'message': 'Eligibility confirmed!',
            'savings': annual_savings
        })
    except Exception as e:
        print(f"Error in join-community API: {e}")
        return jsonify({'status': 'error', 'message': 'Please try again later'}), 500

@app.route('/api/volunteer', methods=['POST'])
def submit_volunteer():
    try:
        data = request.json
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("""
            INSERT INTO volunteers (name, email, phone, interests, availability)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            data['name'],
            data['email'],
            data['phone'],
            data['interests'],
            data['availability']
        ))
        
        connection.commit()
        cursor.close()
        connection.close()
        
        return jsonify({'status': 'success', 'message': 'Thank you for volunteering!'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

# Initialize database when module is imported (with error handling)
try:
    init_database()
    print("Database initialized successfully")
except Exception as e:
    print(f"Database initialization error: {e}")
    print("Application will continue without database functionality")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
