{% if cookiecutter.use_custom_user_model == "yes" -%}
from django.contrib.auth import login
from django.contrib.auth.views import (
    LoginView,
    LogoutView,
    PasswordResetCompleteView,
    PasswordResetConfirmView,
    PasswordResetDoneView,
    PasswordResetView,
)
from django.urls import reverse_lazy
from django.views.generic import CreateView

from .forms import LoginForm, PasswordResetRequestForm, SetNewPasswordForm, UserCreationForm


class UserLoginView(LoginView):
    authentication_form = LoginForm
    template_name = 'users/login.html'
    redirect_authenticated_user = True


class UserLogoutView(LogoutView):
    pass


class SignupView(CreateView):
    form_class = UserCreationForm
    template_name = 'users/signup.html'
    success_url = reverse_lazy('dashboard:index')

    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            from django.shortcuts import redirect
            return redirect(self.success_url)
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        response = super().form_valid(form)
        login(self.request, self.object, backend='django.contrib.auth.backends.ModelBackend')
        return response


class UserPasswordResetView(PasswordResetView):
    form_class = PasswordResetRequestForm
    template_name = 'users/password_reset.html'
    email_template_name = 'users/password_reset_email.html'
    subject_template_name = 'users/password_reset_subject.txt'
    success_url = reverse_lazy('users:password_reset_done')


class UserPasswordResetDoneView(PasswordResetDoneView):
    template_name = 'users/password_reset_done.html'


class UserPasswordResetConfirmView(PasswordResetConfirmView):
    form_class = SetNewPasswordForm
    template_name = 'users/password_reset_confirm.html'
    success_url = reverse_lazy('users:password_reset_complete')


class UserPasswordResetCompleteView(PasswordResetCompleteView):
    template_name = 'users/password_reset_complete.html'
{% endif -%}
