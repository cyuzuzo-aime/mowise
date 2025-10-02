#!/usr/bin/env python3
"""
MoWise - MoMo SMS Processing API
A transaction management system with basic authentication
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import base64
from datetime import datetime
from urllib.parse import urlparse

# ==================== USER DATA ====================
USERS = {
    "admin": "admin123",
    "user": "password",
    "guest": "guest123"
}

# ==================== MODEL ====================
JSON_FILE = "transactions.json"

class TransactionModel:
    """Model for CRUD operations on transactions.json file"""
    
    def __init__(self, json_file=JSON_FILE):
        self.json_file = json_file
        self._ensure_file_exists()
    
    def _ensure_file_exists(self):
        """Create JSON file if it doesn't exist"""
        if not os.path.exists(self.json_file):
            with open(self.json_file, 'w', encoding='utf-8') as f:
                json.dump([], f)
    
    def _read_file(self):
        """Read transactions from JSON file"""
        try:
            with open(self.json_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return []
    
    def _write_file(self, transactions):
        """Write transactions to JSON file"""
        with open(self.json_file, 'w', encoding='utf-8') as f:
            json.dump(transactions, f, indent=2, ensure_ascii=False)
    
    def get_all(self):
        """Get all transactions from file"""
        return self._read_file()
    
    def get_by_id(self, transaction_id):
        """Get single transaction by ID from file"""
        transactions = self._read_file()
        for transaction in transactions:
            if transaction.get('id') == transaction_id:
                return transaction
        return None
    
    def create(self, data):
        """Create new transaction in file"""
        transactions = self._read_file()
        
        # Generate new ID
        if transactions:
            new_id = max(t.get('id', 0) for t in transactions) + 1
        else:
            new_id = 1
        
        # Create new transaction
        new_transaction = {
            'id': new_id,
            'transaction_type': data.get('transaction_type'),
            'amount': data.get('amount'),
            'sender': data.get('sender'),
            'receiver': data.get('receiver'),
            'timestamp': data.get('timestamp', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
            'balance': data.get('balance'),
            'fee': data.get('fee'),
            'date': data.get('date'),
            'raw_body': data.get('raw_body', '')
        }
        
        # Add to list and save to file
        transactions.append(new_transaction)
        self._write_file(transactions)
        
        return new_transaction
    
    def update(self, transaction_id, data):
        """Update existing transaction in file"""
        transactions = self._read_file()
        
        for i, transaction in enumerate(transactions):
            if transaction.get('id') == transaction_id:
                # Update fields (except ID)
                for key, value in data.items():
                    if key != 'id':
                        transaction[key] = value
                
                transactions[i] = transaction
                self._write_file(transactions)
                return transaction
        
        return None
    
    def delete(self, transaction_id):
        """Delete transaction from file"""
        transactions = self._read_file()
        
        for i, transaction in enumerate(transactions):
            if transaction.get('id') == transaction_id:
                deleted = transactions.pop(i)
                self._write_file(transactions)
                return deleted
        
        return None


# ==================== CONTROLLER ====================
class TransactionController:
    """Controller for handling transaction business logic"""
    
    def __init__(self):
        self.model = TransactionModel()
    
    def get_all_transactions(self):
        """Get all transactions"""
        transactions = self.model.get_all()
        return {
            "count": len(transactions),
            "transactions": transactions
        }
    
    def get_transaction(self, transaction_id):
        """Get a single transaction by ID"""
        try:
            tid = int(transaction_id)
            transaction = self.model.get_by_id(tid)
            return transaction
        except ValueError:
            return None
    
    def create_transaction(self, data):
        """Create a new transaction"""
        # Validate required fields
        required_fields = ['transaction_type', 'amount', 'sender', 'receiver']
        
        for field in required_fields:
            if field not in data:
                return {"error": f"Missing required field: {field}"}
        
        # Create transaction
        new_transaction = self.model.create(data)
        return new_transaction
    
    def update_transaction(self, transaction_id, data):
        """Update an existing transaction"""
        try:
            tid = int(transaction_id)
            updated = self.model.update(tid, data)
            
            if updated:
                return updated
            else:
                return {"error": "Transaction not found"}
        except ValueError:
            return {"error": "Invalid transaction ID"}
    
    def delete_transaction(self, transaction_id):
        """Delete a transaction"""
        try:
            tid = int(transaction_id)
            deleted = self.model.delete(tid)
            
            if deleted:
                return {"message": f"Transaction {tid} deleted successfully"}
            else:
                return {"error": "Transaction not found"}
        except ValueError:
            return {"error": "Invalid transaction ID"}


# ==================== REQUEST HANDLER ====================
class MoWiseHandler(BaseHTTPRequestHandler):
    """HTTP Request Handler for MoWise API with Basic Authentication"""
    
    def __init__(self, *args, **kwargs):
        self.controller = TransactionController()
        super().__init__(*args, **kwargs)
    
    def _authenticate(self):
        """Verify Basic Authentication credentials"""
        auth_header = self.headers.get('Authorization')
        
        if not auth_header:
            return False, None
        
        try:
            # Parse "Basic base64string"
            auth_type, auth_string = auth_header.split(' ', 1)
            
            if auth_type.lower() != 'basic':
                return False, None
            
            # Decode base64
            decoded = base64.b64decode(auth_string).decode('utf-8')
            username, password = decoded.split(':', 1)
            
            # Check credentials
            if username in USERS and USERS[username] == password:
                return True, username
            
            return False, None
            
        except (ValueError, KeyError):
            return False, None
    
    def _send_json(self, data, status=200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))
    
    def _send_auth_required(self):
        """Send 401 Unauthorized response"""
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="MoWise API"')
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"error": "Unauthorized"}).encode("utf-8"))
    
    def _parse_path(self):
        """Parse the path to extract route and ID"""
        parsed = urlparse(self.path)
        path_parts = parsed.path.strip('/').split('/')
        
        route = path_parts[0] if path_parts else ''
        resource_id = path_parts[1] if len(path_parts) > 1 else None
        
        return route, resource_id
    
    def _read_body(self):
        """Read and parse JSON body"""
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            return None
        
        body = self.rfile.read(content_length)
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return None
    
    def do_GET(self):
        """Handle GET requests"""
        # Check authentication
        is_authenticated, username = self._authenticate()
        if not is_authenticated:
            self._send_auth_required()
            return
        
        route, resource_id = self._parse_path()
        
        if route == "transactions":
            if resource_id:
                # GET /transactions/{id}
                result = self.controller.get_transaction(resource_id)
                if result:
                    self._send_json(result, 200)
                else:
                    self._send_json({"error": "Transaction not found"}, 404)
            else:
                # GET /transactions
                result = self.controller.get_all_transactions()
                self._send_json(result, 200)
        elif route == "":
            # Root endpoint
            self._send_json({
                "app": "MoWise",
                "description": "MoMo SMS Processing API",
                "version": "1.0",
                "authenticated_user": username
            }, 200)
        else:
            self._send_json({"error": "Not Found"}, 404)
    
    def do_POST(self):
        """Handle POST requests"""
        # Check authentication
        is_authenticated, username = self._authenticate()
        if not is_authenticated:
            self._send_auth_required()
            return
        
        route, resource_id = self._parse_path()
        
        if route == "transactions" and not resource_id:
            data = self._read_body()
            
            if data is None:
                self._send_json({"error": "Invalid JSON"}, 400)
                return
            
            result = self.controller.create_transaction(data)
            if "error" in result:
                self._send_json(result, 400)
            else:
                self._send_json(result, 201)
        else:
            self._send_json({"error": "Not Found"}, 404)
    
    def do_PUT(self):
        """Handle PUT requests"""
        # Check authentication
        is_authenticated, username = self._authenticate()
        if not is_authenticated:
            self._send_auth_required()
            return
        
        route, resource_id = self._parse_path()
        
        if route == "transactions" and resource_id:
            data = self._read_body()
            
            if data is None:
                self._send_json({"error": "Invalid JSON"}, 400)
                return
            
            result = self.controller.update_transaction(resource_id, data)
            if "error" in result:
                status = 404 if "not found" in result["error"].lower() else 400
                self._send_json(result, status)
            else:
                self._send_json(result, 200)
        else:
            self._send_json({"error": "Not Found"}, 404)
    
    def do_DELETE(self):
        """Handle DELETE requests"""
        # Check authentication
        is_authenticated, username = self._authenticate()
        if not is_authenticated:
            self._send_auth_required()
            return
        
        route, resource_id = self._parse_path()
        
        if route == "transactions" and resource_id:
            result = self.controller.delete_transaction(resource_id)
            if "error" in result:
                self._send_json(result, 404)
            else:
                self._send_json(result, 200)
        else:
            self._send_json({"error": "Not Found"}, 404)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom log format"""
        print(f"[{self.log_date_time_string()}] {format % args}")


# ==================== SERVER ====================
def run(server_class=HTTPServer, handler_class=MoWiseHandler, port=8000):
    """Start the MoWise API server"""
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    
    print("=" * 60)
    print("MoWise - MoMo SMS Processing API")
    print("=" * 60)
    print(f"Server running at http://127.0.0.1:{port}")
    print(f"\nAuthentication Required:")
    print(f"  Username: admin | Password: admin123")
    print(f"  Username: user  | Password: password")
    print(f"  Username: guest | Password: guest123")
    print(f"\nAvailable endpoints:")
    print(f"  GET    /                   - API info")
    print(f"  GET    /transactions       - List all transactions")
    print(f"  GET    /transactions/{{id}}  - Get one transaction")
    print(f"  POST   /transactions       - Create new transaction")
    print(f"  PUT    /transactions/{{id}}  - Update transaction")
    print(f"  DELETE /transactions/{{id}}  - Delete transaction")
    print(f"\nExample curl command:")
    print(f"  curl -u admin:admin123 http://127.0.0.1:{port}/transactions")
    print("=" * 60)
    
    httpd.serve_forever()


if __name__ == "__main__":
    run()