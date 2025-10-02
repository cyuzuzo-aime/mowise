import xml.etree.ElementTree as ET
import json
import re
from datetime import datetime

def extract_transaction_details(body):
    """
    Extract transaction details from SMS body.
    
    Returns:
        Dictionary with transaction_type, amount, sender, receiver, timestamp
    """
    details = {
        'transaction_type': None,
        'amount': None,
        'sender': None,
        'receiver': None,
        'timestamp': None,
        'balance': None,
        'fee': None
    }
    
    if not body:
        return details
    
    # Extract timestamp (format: YYYY-MM-DD HH:MM:SS)
    timestamp_match = re.search(r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})', body)
    if timestamp_match:
        details['timestamp'] = timestamp_match.group(1)
    
    # Extract amount (format: X,XXX RWF or XXXX RWF)
    amount_match = re.search(r'([\d,]+)\s*RWF', body)
    if amount_match:
        details['amount'] = amount_match.group(1).replace(',', '')
    
    # Extract balance
    balance_match = re.search(r'(?:new balance|NEW BALANCE)\s*:?\s*([\d,]+)\s*RWF', body, re.IGNORECASE)
    if balance_match:
        details['balance'] = balance_match.group(1).replace(',', '')
    
    # Extract fee
    fee_match = re.search(r'[Ff]ee\s+was:?\s*([\d,]+)\s*RWF', body)
    if fee_match:
        details['fee'] = fee_match.group(1).replace(',', '')
    
    # Determine transaction type and extract sender/receiver
    if 'received' in body.lower():
        details['transaction_type'] = 'received'
        # Extract sender name and phone
        sender_match = re.search(r'from\s+([A-Za-z\s]+)\s*\(\*+(\d+)\)', body)
        if sender_match:
            details['sender'] = sender_match.group(1).strip()
        details['receiver'] = 'You'
        
    elif 'payment' in body.lower() and 'to' in body.lower():
        details['transaction_type'] = 'payment'
        details['sender'] = 'You'
        # Extract receiver name
        receiver_match = re.search(r'to\s+([A-Za-z\s]+?)(?:\s+\d+|\s+with)', body)
        if receiver_match:
            details['receiver'] = receiver_match.group(1).strip()
        elif 'Airtime' in body:
            details['receiver'] = 'Airtime'
            details['transaction_type'] = 'airtime_purchase'
    
    elif 'transferred to' in body.lower():
        details['transaction_type'] = 'transfer'
        details['sender'] = 'You'
        # Extract receiver name and phone
        receiver_match = re.search(r'to\s+([A-Za-z\s]+)\s*\((\d+)\)', body)
        if receiver_match:
            details['receiver'] = receiver_match.group(1).strip()
    
    elif 'deposit' in body.lower():
        details['transaction_type'] = 'deposit'
        details['sender'] = 'Bank/Cash'
        details['receiver'] = 'You'
    
    return details

def parse_sms_xml(xml_content):
    """
    Parse SMS backup XML and convert to structured JSON objects.
    
    Args:
        xml_content: String containing the XML content
    
    Returns:
        List of dictionaries with transaction details
    """
    root = ET.fromstring(xml_content)
    
    transactions = []
    
    for idx, sms in enumerate(root.findall('sms'), start=1):
        body = sms.get('body', '')
        date = sms.get('date')
        readable_date = sms.get('readable_date')
        
        # Extract transaction details from body
        details = extract_transaction_details(body)
        
        # Create transaction object with only meaningful fields
        transaction = {
            'id': idx,
            'transaction_type': details['transaction_type'],
            'amount': details['amount'],
            'sender': details['sender'],
            'receiver': details['receiver'],
            'timestamp': details['timestamp'],
            'balance': details['balance'],
            'fee': details['fee'],
            'date': readable_date,
            'raw_body': body  # Keep for reference if needed
        }
        
        transactions.append(transaction)
    
    return transactions

# Example usage
if __name__ == "__main__":
    # Read your XML file
    with open('modified_sms_v2.xml', 'r', encoding='utf-8') as f:
        xml_content = f.read()
    
    # Parse transactions
    transactions = parse_sms_xml(xml_content)
    
    # Convert to JSON
    json_output = json.dumps(transactions, indent=2, ensure_ascii=False)
    
    # Print summary
    print(f"Parsed {len(transactions)} transactions\n")
    
    # Print first few transactions
    print("Sample transactions:")
    for i, tx in enumerate(transactions[:3]):
        print(f"\nTransaction {i+1}:")
        print(f"  Type: {tx['transaction_type']}")
        print(f"  Amount: {tx['amount']} RWF")
        print(f"  From: {tx['sender']} → To: {tx['receiver']}")
        print(f"  Balance: {tx['balance']} RWF")
        print(f"  Date: {tx['date']}")
    
    # Save to JSON file
    with open('transactions.json', 'w', encoding='utf-8') as f:
        f.write(json_output)
    
    print(f"\n✓ All transactions saved to transactions.json")