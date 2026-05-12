{% if cookiecutter.use_custom_user_model == "yes" -%}
"""
Custom User model.
"""
from django.contrib.auth.models import AbstractUser{% if cookiecutter.use_email_as_username == "yes" %}, BaseUserManager{% endif %}
from django.db import models

{% if cookiecutter.use_email_as_username == "yes" -%}

class UserManager(BaseUserManager):
    """Custom user manager for email-based authentication."""
    
    def create_user(self, email, password=None, **extra_fields):
        """Create and save a regular user with the given email and password."""
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        """Create and save a superuser with the given email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email, password, **extra_fields)
{% endif -%}

class User(AbstractUser):
    """
    Custom user model extending Django's AbstractUser.
    
    This allows for future customization while maintaining
    all of Django's built-in authentication features.
    
    Add custom fields here as needed, for example:
    - bio = models.TextField(blank=True)
    - avatar = models.ImageField(upload_to='avatars/', blank=True)
    - phone_number = models.CharField(max_length=20, blank=True)
    """
    {% if cookiecutter.use_email_as_username == "yes" -%}
    # Make email the primary identifier instead of username
    username = None
    email = models.EmailField('email address', unique=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []  # Email is already required as USERNAME_FIELD
    
    objects = UserManager()
    {% endif -%}
    
    class Meta:
        verbose_name = 'user'
        verbose_name_plural = 'users'
    
    def __str__(self):
        {% if cookiecutter.use_email_as_username == "yes" -%}
        return self.email
        {% else -%}
        return self.username
        {% endif -%}
{% endif -%}
