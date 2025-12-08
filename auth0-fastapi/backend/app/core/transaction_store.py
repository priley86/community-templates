"""
In-memory transaction store to avoid cross-site cookie issues.

This is needed for the Connected Accounts flow where the user is redirected through
third-party identity providers (e.g., Google) and then back to our callback.

Cookie-based transaction stores fail in cross-site redirect scenarios because:
1. SameSite=Lax cookies aren't sent on cross-site redirects from third parties
2. SameSite=None cookies may still fail due to browser restrictions or proxy issues

The in-memory store avoids all cookie issues by storing transaction data server-side.
Note: This won't work if you scale to multiple instances without sticky sessions.
For multi-instance deployments, consider using Redis or a database.
"""

import time
from typing import Any, Optional

from auth0_server_python.auth_types import TransactionData
from auth0_server_python.store.abstract import TransactionStore


class InMemoryTransactionStore(TransactionStore):
    """
    Transaction store implementation that uses server-side memory.
    
    This store is designed to work with cross-site redirect flows like the
    Connected Accounts flow where the user is redirected through third-party
    identity providers.
    
    Transactions are stored in memory with automatic expiration.
    """
    
    # Class-level storage shared across all instances
    _transactions: dict[str, tuple[TransactionData, float]] = {}
    
    def __init__(self, secret: str, expiration_seconds: int = 300):
        super().__init__({"secret": secret})
        self.expiration_seconds = expiration_seconds

    def _cleanup_expired(self) -> None:
        """Remove expired transactions."""
        now = time.time()
        expired_keys = [
            key for key, (_, expiry) in self._transactions.items()
            if now > expiry
        ]
        for key in expired_keys:
            del self._transactions[key]

    async def set(
        self,
        identifier: str,
        value: TransactionData,
        options: Optional[dict[str, Any]] = None,
    ) -> None:
        """
        Stores the transaction data in memory.
        The identifier (state parameter) is used as the key.
        """
        # Cleanup expired transactions periodically
        self._cleanup_expired()
        
        expiry_time = time.time() + self.expiration_seconds
        self._transactions[identifier] = (value, expiry_time)

    async def get(
        self,
        identifier: str,
        options: Optional[dict[str, Any]] = None,
    ) -> Optional[TransactionData]:
        """
        Retrieves the transaction data from memory using the identifier.
        """
        # Cleanup expired transactions periodically
        self._cleanup_expired()
        
        if identifier not in self._transactions:
            return None
        
        value, expiry = self._transactions[identifier]
        
        # Check if expired
        if time.time() > expiry:
            del self._transactions[identifier]
            return None
        
        return value

    async def delete(
        self,
        identifier: str,
        options: Optional[dict[str, Any]] = None,
    ) -> None:
        """
        Deletes the transaction data from memory.
        """
        if identifier in self._transactions:
            del self._transactions[identifier]
