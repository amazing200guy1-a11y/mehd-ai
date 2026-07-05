"""
Mehd AI — Ghost Account Purger
=================================
This script connects to the live Firebase Authentication pool and safely
removes unverified, old, or explicitly marked "test" accounts.

Run this locally with Admin SDK credentials to clean the vault.
"""

import firebase_admin
from firebase_admin import credentials, auth
from datetime import datetime, timezone, timedelta

def initialize_firebase():
    """Initialize Firebase Admin SDK. Requires GOOGLE_APPLICATION_CREDENTIALS in env."""
    try:
        firebase_admin.get_app()
    except ValueError:
        # Assumes credentials are in environment or default path
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)

def purge_ghost_accounts():
    print("Starting the Ghost Account sweep...")
    initialize_firebase()
    
    deleted_count = 0
    now = datetime.now(timezone.utc)
    
    # Iterate through all users in batches of 1000
    page = auth.list_users()
    while page:
        for user in page.users:
            should_delete = False
            reason = ""
            
            # Rule 1: Email contains test/mock
            email = user.email.lower() if user.email else ""
            if "test@" in email or "mock" in email or "@test.com" in email:
                should_delete = True
                reason = "Test/Mock email pattern"
                
            # Rule 2: Unverified email older than 24 hours
            elif not user.email_verified:
                creation_time = datetime.fromtimestamp(user.user_metadata.creation_timestamp / 1000, tz=timezone.utc)
                if now - creation_time > timedelta(hours=24):
                    should_delete = True
                    reason = "Unverified email older than 24h"
            
            if should_delete:
                print(f"🗑️ Deleting user {user.uid} ({email}) - Reason: {reason}")
                auth.delete_user(user.uid)
                deleted_count += 1

        # Get next page
        page = page.get_next_page()

    print(f"✅ Sweep complete. {deleted_count} ghost accounts purged.")

if __name__ == "__main__":
    purge_ghost_accounts()
