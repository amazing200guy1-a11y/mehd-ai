import base64
import hashlib
import os
import logging
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("test_crypto")

class NewDataEncryption:
    def __init__(self, master_key: str):
        self._master_key = master_key
        # For legacy compatibility, compute the legacy Fernet instance once
        if master_key:
            legacy_bytes = hashlib.sha256(master_key.encode("utf-8")).digest()
            self._legacy_fernet = Fernet(base64.urlsafe_b64encode(legacy_bytes))
        else:
            self._legacy_fernet = None

    def encrypt(self, plain_text: str) -> str:
        if not plain_text:
            return ""
        if not self._master_key:
            return plain_text  # Plain text fallback if key missing

        # Generate a random 16-byte salt
        salt = os.urandom(16)
        
        # Derive key via PBKDF2
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=600000,  # 600k production-grade iterations
        )
        derived_key = base64.urlsafe_b64encode(kdf.derive(self._master_key.encode("utf-8")))
        
        # Encrypt
        f = Fernet(derived_key)
        ciphertext = f.encrypt(plain_text.encode("utf-8"))
        
        # Format: v2:salt_b64:ciphertext_b64
        salt_b64 = base64.b64encode(salt).decode("utf-8")
        ciphertext_b64 = base64.b64encode(ciphertext).decode("utf-8")
        return f"v2:{salt_b64}:{ciphertext_b64}"

    def decrypt(self, encrypted_text: str) -> str:
        if not encrypted_text:
            return ""
        if not self._master_key:
            return encrypted_text

        # Check for v2 format
        if encrypted_text.startswith("v2:"):
            try:
                parts = encrypted_text.split(":")
                if len(parts) != 3:
                    raise ValueError("Malformed v2 encrypted text")
                
                salt = base64.b64decode(parts[1])
                ciphertext = base64.b64decode(parts[2])
                
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA256(),
                    length=32,
                    salt=salt,
                    iterations=600000,
                )
                derived_key = base64.urlsafe_b64encode(kdf.derive(self._master_key.encode("utf-8")))
                f = Fernet(derived_key)
                return f.decrypt(ciphertext).decode("utf-8")
            except Exception as e:
                logger.error("Failed to decrypt v2 format: %s", e)
                return ""
        
        # Legacy fallback
        try:
            if self._legacy_fernet:
                return self._legacy_fernet.decrypt(encrypted_text.encode("utf-8")).decode("utf-8")
        except Exception as e:
            logger.error("Failed to decrypt legacy format: %s", e)
        return ""

# Test Cases
import time
master = "super-secret-master-key"
data = "my-broker-api-key-12345"

# 1. Test legacy data encryption and decryption
legacy_bytes = hashlib.sha256(master.encode("utf-8")).digest()
legacy_fernet = Fernet(base64.urlsafe_b64encode(legacy_bytes))
legacy_encrypted = legacy_fernet.encrypt(data.encode("utf-8")).decode("utf-8")

crypto = NewDataEncryption(master)
decrypted_legacy = crypto.decrypt(legacy_encrypted)
assert decrypted_legacy == data, f"Legacy decryption failed: {decrypted_legacy} != {data}"
logger.info("✅ Legacy decryption fallback works!")

# 2. Test new v2 encryption and decryption
start_enc = time.perf_counter()
v2_encrypted = crypto.encrypt(data)
end_enc = time.perf_counter()
assert v2_encrypted.startswith("v2:"), f"V2 encrypted prefix missing: {v2_encrypted}"

start_dec = time.perf_counter()
decrypted_v2 = crypto.decrypt(v2_encrypted)
end_dec = time.perf_counter()
assert decrypted_v2 == data, f"V2 decryption failed: {decrypted_v2} != {data}"
logger.info("✅ V2 encryption and decryption works!")
logger.info(f"V2 encryption took: {end_enc - start_enc:.4f} seconds")
logger.info(f"V2 decryption took: {end_dec - start_dec:.4f} seconds")
logger.info(f"V2 ciphertext example: {v2_encrypted}")
