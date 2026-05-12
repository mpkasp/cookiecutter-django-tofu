from django import forms
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.core.exceptions import ValidationError

from django_recaptcha.fields import ReCaptchaField

User = get_user_model()


class UserCreationForm(UserCreationForm):
    first_name = forms.CharField(required=True)
    last_name = forms.CharField(required=True)
    {% if cookiecutter.use_email_as_username == "no" -%}
    email = forms.EmailField(required=True)
    {% endif -%}
    captcha = ReCaptchaField(label='')

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ({% if cookiecutter.use_email_as_username == "no" %}"username", {% endif %}"email", "first_name", "last_name")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        skip_captcha = settings.DEBUG or getattr(settings, "RECAPTCHA_TESTING", False)

        self.fields['captcha'].required = not skip_captcha
        if skip_captcha:
            del self.fields['captcha']

    def clean_email(self):
        email = self.cleaned_data['email']
        # Check if email already exists, excluding current user if updating (though this is CreationForm)
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError('An account with this email address already exists.')
        return email

    def save(self, commit=True):
        user = super().save(commit=commit)
        user.email = self.cleaned_data['email']
        user.first_name = self.cleaned_data['first_name']
        user.last_name = self.cleaned_data['last_name']
        if commit:
            user.save()
        return user


class UserChangeForm(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User
