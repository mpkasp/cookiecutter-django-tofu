from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from .forms import UserCreationForm

User = get_user_model()

class UserFormTests(TestCase):
    """Tests for User forms."""

    def test_user_creation_form_captcha_skip_in_debug(self):
        """Test that captcha is removed in DEBUG mode."""
        with override_settings(DEBUG=True):
            form = UserCreationForm()
            self.assertNotIn('captcha', form.fields)

    def test_user_creation_form_captcha_skip_in_testing(self):
        """Test that captcha is removed when RECAPTCHA_TESTING is True."""
        with override_settings(DEBUG=False, RECAPTCHA_TESTING=True):
            form = UserCreationForm()
            self.assertNotIn('captcha', form.fields)

    def test_user_creation_form_captcha_required_in_production(self):
        """Test that captcha is required when not in DEBUG or RECAPTCHA_TESTING."""
        with override_settings(DEBUG=False, RECAPTCHA_TESTING=False):
            form = UserCreationForm()
            self.assertIn('captcha', form.fields)
            self.assertTrue(form.fields['captcha'].required)

    def test_user_creation_form_validation(self):
        """Test form validation with common fields."""
        data = {
            'first_name': 'Test',
            'last_name': 'User',
            'email': 'test@example.com',
            {% if cookiecutter.use_email_as_username == "no" -%}
            'username': 'testuser',
            {% endif -%}
            'password1': 'testpass123',
            'password2': 'testpass123',
        }
        # In testing mode captcha should be removed
        with override_settings(RECAPTCHA_TESTING=True):
            form = UserCreationForm(data=data)
            self.assertTrue(form.is_valid(), form.errors)
            user = form.save()
            self.assertEqual(user.email, 'test@example.com')
            self.assertEqual(user.first_name, 'Test')
            self.assertEqual(user.last_name, 'User')
