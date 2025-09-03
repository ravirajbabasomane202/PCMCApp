import requests
import json

BASE_URL = "http://127.0.0.1:5000"

# Test users
USERS = {
    "citizen": "citizen@test.com",
    "member_head": "memberhead@test.com",
    "field_staff": "fieldstaff@test.com",
    "admin": "admin@test.com",
}
PASSWORD = "password123"

# Endpoints from flask routes (placeholders replaced)
ROUTES = [
    ("GET", "/admins/kpis/advanced"),
    ("GET", "/admins/users/history"),
    ("GET", "/admins/audit-logs"),
    ("GET", "/admins/users/1/history"),
    ("POST", "/admins/announcements"),
    ("GET", "/admins/dashboard"),
    ("POST", "/admins/grievances/1/escalate"),
    ("GET", "/admins/reports/kpis/advanced"),
    ("GET", "/admins/grievances/all"),
    ("GET", "/admins/announcements"),
    ("GET", "/admins/areas"),
    ("GET", "/admins/subjects"),
    ("GET", "/admins/users"),
    ("GET", "/admins/reports/location"),
    ("POST", "/admins/areas"),
    ("GET", "/admins/configs"),
    ("POST", "/admins/configs"),
    ("POST", "/admins/subjects"),
    ("POST", "/admins/reassign/1"),
    ("GET", "/admins/reports"),
    ("GET", "/admins/reports/staff-performance"),
    ("PUT", "/admins/configs/MAX_ESCALATION_LEVEL"),
    ("PUT", "/admins/users/1"),
    ("GET", "/auth/me"),
    ("GET", "/auth/google/callback"),
    ("GET", "/auth/google/login"),
    ("POST", "/auth/guest-login"),
    ("POST", "/auth/login"),
    ("POST", "/auth/refresh"),
    ("POST", "/auth/register"),
    ("POST", "/auth/otp/send"),
    ("POST", "/auth/otp/verify"),
    ("POST", "/grievances/1/accept"),
    ("POST", "/grievances/1/comments"),
    ("GET", "/grievances/assigned"),
    ("POST", "/grievances/1/close"),
    ("POST", "/grievances/"),
    ("POST", "/grievances/1/escalate"),
    ("GET", "/grievances/admin/grievances/all"),
    ("GET", "/grievances/1"),
    ("GET", "/grievances/admin/1"),
    ("GET", "/grievances/mine"),
    ("GET", "/grievances/new"),
    ("PUT", "/grievances/1/reassign"),
    ("POST", "/grievances/1/reject"),
    ("GET", "/grievances/1/rejection"),
    ("GET", "/grievances/search/TEST123"),
    ("POST", "/grievances/1/feedback"),
    ("GET", "/grievances/track"),
    ("PUT", "/grievances/1/status"),
    ("POST", "/grievances/1/workproof"),
    ("POST", "/notifications/register"),
    ("GET", "/areas"),
    ("GET", "/subjects"),
    ("GET", "/settings/settings"),
    ("POST", "/settings/settings"),
    ("GET", "/users/admin/users"),
    ("POST", "/users/admin/users"),
    ("DELETE", "/users/admin/users/1"),
    ("GET", "/users/1"),
    ("GET", "/users/"),
]

def login(email, password):
    url = f"{BASE_URL}/auth/login"
    resp = requests.post(url, json={"email": email, "password": password})
    if resp.status_code == 200 and "access_token" in resp.json():
        return resp.json()["access_token"]
    print(f"❌ Login failed for {email}: {resp.status_code} {resp.text}")
    return None

def pretty_json(data, length=200):
    """Return truncated JSON for logging"""
    try:
        txt = json.dumps(data, indent=2)
        return txt[:length] + ("..." if len(txt) > length else "")
    except Exception:
        return str(data)

def test_routes_for_user(role, token):
    print(f"\n=== Testing routes for {role.upper()} ===")
    headers = {"Authorization": f"Bearer {token}"} if token else {}

    for method, route in ROUTES:
        url = f"{BASE_URL}{route}"
        try:
            if method == "GET":
                resp = requests.get(url, headers=headers)
            elif method == "POST":
                resp = requests.post(url, headers=headers, json={})
            elif method == "PUT":
                resp = requests.put(url, headers=headers, json={})
            elif method == "DELETE":
                resp = requests.delete(url, headers=headers)
            else:
                continue

            status = resp.status_code
            out = f"{method:6s} {route:40s} => {status}"

            # Add response details
            if status == 200:
                try:
                    out += f" | {pretty_json(resp.json())}"
                except Exception:
                    out += f" | {resp.text[:100]}"
            else:
                out += f" | {resp.reason} {resp.text[:80]}"

            print(out)

        except Exception as e:
            print(f"{method:6s} {route:40s} => ERROR {e}")

if __name__ == "__main__":
    for role, email in USERS.items():
        token = login(email, PASSWORD)
        test_routes_for_user(role, token)
