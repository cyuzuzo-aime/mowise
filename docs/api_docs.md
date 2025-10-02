# MoWise API - Postman Usage Guide

## Setting Up Authentication in Postman

1. Open Postman and create a new request
2. Go to the **Authorization** tab
3. Select **Basic Auth** from the Type dropdown
4. Enter credentials:
   - **Username:** `admin`
   - **Password:** `admin123`
   
   (Or use `user:password` or `guest:guest123`)

---

## Endpoint Examples

### 1. Get API Info

**Method:** `GET`  
**URL:** `http://127.0.0.1:8000/`

**Steps:**
1. Set method to GET
2. Enter URL: `http://127.0.0.1:8000/`
3. Configure Basic Auth (see above)
4. Click **Send**

---

### 2. Get All Transactions

**Method:** `GET`  
**URL:** `http://127.0.0.1:8000/transactions`

**Steps:**
1. Set method to GET
2. Enter URL: `http://127.0.0.1:8000/transactions`
3. Configure Basic Auth
4. Click **Send**

---

### 3. Get Transaction by ID

**Method:** `GET`  
**URL:** `http://127.0.0.1:8000/transactions/1`

**Steps:**
1. Set method to GET
2. Enter URL: `http://127.0.0.1:8000/transactions/1`
   - Replace `1` with any transaction ID
3. Configure Basic Auth
4. Click **Send**

---

### 4. Create Transaction

**Method:** `POST`  
**URL:** `http://127.0.0.1:8000/transactions`

**Steps:**
1. Set method to POST
2. Enter URL: `http://127.0.0.1:8000/transactions`
3. Configure Basic Auth
4. Go to the **Body** tab
5. Select **raw**
6. Select **JSON** from the dropdown (right side)
7. Enter request body:

```json
{
  "transaction_type": "transfer",
  "amount": "10000",
  "sender": "You",
  "receiver": "Jane Smith",
  "balance": "15000",
  "fee": "100"
}
```

8. Click **Send**

**Required Fields:**
- `transaction_type`
- `amount`
- `sender`
- `receiver`

---

### 5. Update Transaction

**Method:** `PUT`  
**URL:** `http://127.0.0.1:8000/transactions/3`

**Steps:**
1. Set method to PUT
2. Enter URL: `http://127.0.0.1:8000/transactions/3`
   - Replace `3` with the transaction ID you want to update
3. Configure Basic Auth
4. Go to the **Body** tab
5. Select **raw**
6. Select **JSON** from the dropdown
7. Enter fields to update:

```json
{
  "amount": "12000",
  "fee": "150"
}
```

8. Click **Send**

---

### 6. Delete Transaction

**Method:** `DELETE`  
**URL:** `http://127.0.0.1:8000/transactions/3`

**Steps:**
1. Set method to DELETE
2. Enter URL: `http://127.0.0.1:8000/transactions/3`
   - Replace `3` with the transaction ID you want to delete
3. Configure Basic Auth
4. Click **Send**

---

## Quick Setup Tips


### Create a Collection

1. Click **Collections** in the sidebar
2. Create new collection: "MoWise API"
3. Add all 6 endpoints to the collection
4. Set authentication at the collection level:
   - Click collection → **Authorization** tab
   - Set Basic Auth with these credintials: username: admin --- password: admin123
   - All requests inherit this authentication

---

## Common Issues

### 401 Unauthorized
- Check that Basic Auth is enabled
- Verify username and password are correct
- Ensure credentials are entered in the Authorization tab, not manually in headers

### Invalid JSON Error
- Verify **raw** is selected in Body tab
- Ensure **JSON** is selected from the dropdown
- Check JSON syntax (use Postman's prettify feature)

### Connection Refused
- Verify the server is running: `python3 MoWise_Server.py`

---

## Testing Workflow

1. **Start with GET /**: Verify API is running
2. **GET /transactions**: See existing data
3. **POST /transactions**: Create a new transaction
4. **GET /transactions/{id}**: Retrieve the transaction you just created
5. **PUT /transactions/{id}**: Update the transaction
6. **DELETE /transactions/{id}**: Delete the transaction
7. **GET /transactions**: Verify deletion

---

## Sample Postman Collection JSON

Import this into Postman (Go to File, and then Import):

```json
{
  "info": {
    "name": "MoWise API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {
    "type": "basic",
    "basic": [
      {"key": "username", "value": "admin"},
      {"key": "password", "value": "admin123"}
    ]
  },
  "item": [
    {
      "name": "Get API Info",
      "request": {
        "method": "GET",
        "url": "http://127.0.0.1:8000/"
      }
    },
    {
      "name": "Get All Transactions",
      "request": {
        "method": "GET",
        "url": "http://127.0.0.1:8000/transactions"
      }
    },
    {
      "name": "Get Transaction by ID",
      "request": {
        "method": "GET",
        "url": "http://127.0.0.1:8000/transactions/1"
      }
    },
    {
      "name": "Create Transaction",
      "request": {
        "method": "POST",
        "url": "http://127.0.0.1:8000/transactions",
        "header": [
          {"key": "Content-Type", "value": "application/json"}
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"transaction_type\": \"transfer\",\n  \"amount\": \"10000\",\n  \"sender\": \"You\",\n  \"receiver\": \"Jane Smith\",\n  \"balance\": \"15000\",\n  \"fee\": \"100\"\n}"
        }
      }
    },
    {
      "name": "Update Transaction",
      "request": {
        "method": "PUT",
        "url": "http://127.0.0.1:8000/transactions/3",
        "header": [
          {"key": "Content-Type", "value": "application/json"}
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"amount\": \"12000\",\n  \"fee\": \"150\"\n}"
        }
      }
    },
    {
      "name": "Delete Transaction",
      "request": {
        "method": "DELETE",
        "url": "http://127.0.0.1:8000/transactions/3"
      }
    }
  ]
}
```

Copy this JSON and import it into Postman to get all endpoints pre-configured!