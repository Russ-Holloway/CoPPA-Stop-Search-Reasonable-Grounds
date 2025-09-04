"""
Security monitoring and logging utilities
"""
import logging
import time
from collections import defaultdict
from typing import Dict, List
import os

# Security event logger
security_logger = logging.getLogger("security")
security_logger.setLevel(logging.INFO)

# Create security log handler if not exists
if not security_logger.handlers:
    log_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    handler = logging.FileHandler(os.path.join(log_dir, "security.log"))
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    security_logger.addHandler(handler)

class SecurityMonitor:
    """Monitor and track security events"""
    
    def __init__(self):
        self.suspicious_activities = defaultdict(list)
        self.blocked_ips = set()
        
    def log_suspicious_activity(self, client_ip: str, activity_type: str, details: str = ""):
        """Log suspicious activity"""
        timestamp = time.time()
        activity = {
            "timestamp": timestamp,
            "type": activity_type,
            "details": details
        }
        
        self.suspicious_activities[client_ip].append(activity)
        
        # Log to security logger
        security_logger.warning(
            f"Suspicious activity detected - IP: {client_ip}, "
            f"Type: {activity_type}, Details: {details}"
        )
        
        # Check if IP should be blocked (more than 5 suspicious activities in 10 minutes)
        recent_activities = [
            a for a in self.suspicious_activities[client_ip] 
            if timestamp - a["timestamp"] < 600  # 10 minutes
        ]
        
        if len(recent_activities) >= 5:
            self.blocked_ips.add(client_ip)
            security_logger.error(f"IP {client_ip} blocked due to repeated suspicious activities")
    
    def log_rate_limit_exceeded(self, client_ip: str, endpoint: str):
        """Log rate limit violations"""
        self.log_suspicious_activity(
            client_ip, 
            "RATE_LIMIT_EXCEEDED", 
            f"Endpoint: {endpoint}"
        )
    
    def log_invalid_input(self, client_ip: str, input_type: str, value: str = ""):
        """Log invalid input attempts"""
        # Don't log the actual value for security, just the type
        self.log_suspicious_activity(
            client_ip,
            "INVALID_INPUT",
            f"Type: {input_type}"
        )
    
    def is_blocked(self, client_ip: str) -> bool:
        """Check if IP is blocked"""
        return client_ip in self.blocked_ips
    
    def get_client_ip(self, request_environ: dict) -> str:
        """Extract client IP from request"""
        return request_environ.get(
            'HTTP_X_REAL_IP', 
            request_environ.get(
                'HTTP_X_FORWARDED_FOR', 
                request_environ.get('REMOTE_ADDR', '0.0.0.0')
            )
        )

# Global security monitor instance
security_monitor = SecurityMonitor()
