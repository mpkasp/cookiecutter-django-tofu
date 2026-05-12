import json

import pytest


@pytest.fixture
def client(db, client):
    """Django test client with database access."""
    return client


@pytest.fixture
def admin_user(db, django_user_model):
    return django_user_model.objects.create_superuser(
        {% if cookiecutter.use_email_as_username == "yes" -%}
        email="admin@example.com",
        {% else -%}
        username="admin",
        email="admin@example.com",
        {% endif -%}
        password="testpass123",
    )


@pytest.fixture
def logged_in_client(client, admin_user):
    client.force_login(admin_user)
    return client


class TestHealthCheck:
    def test_health_endpoint_returns_200(self, client):
        response = client.get("/health/")
        assert response.status_code == 200

    def test_health_endpoint_returns_healthy_status(self, client):
        response = client.get("/health/")
        assert json.loads(response.content)["status"] == "healthy"
