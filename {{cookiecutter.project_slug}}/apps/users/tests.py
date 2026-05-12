{% if cookiecutter.use_custom_user_model == "yes" -%}
"""
Tests for custom User model.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model

User = get_user_model()


class UserModelTests(TestCase):
    """Tests for the custom User model."""
    
    def test_create_user(self):
        """Test creating a user with email and password."""
        email = 'test@example.com'
        password = 'testpass123'
        {% if cookiecutter.use_email_as_username == "yes" -%}
        
        user = User.objects.create_user(
            email=email,
            password=password
        )
        
        self.assertEqual(user.email, email)
        self.assertTrue(user.check_password(password))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
        {% else -%}
        username = 'testuser'
        
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password
        )
        
        self.assertEqual(user.email, email)
        self.assertEqual(user.username, username)
        self.assertTrue(user.check_password(password))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
        {% endif -%}
    
    def test_create_superuser(self):
        """Test creating a superuser."""
        email = 'admin@example.com'
        password = 'testpass123'
        {% if cookiecutter.use_email_as_username == "yes" -%}
        
        user = User.objects.create_superuser(
            email=email,
            password=password
        )
        
        self.assertEqual(user.email, email)
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        {% else -%}
        username = 'admin'
        
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        
        self.assertEqual(user.email, email)
        self.assertEqual(user.username, username)
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        {% endif -%}
{% endif -%}
