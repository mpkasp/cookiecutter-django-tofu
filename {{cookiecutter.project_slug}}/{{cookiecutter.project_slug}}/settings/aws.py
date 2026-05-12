"""
AWS production settings.
"""
from .production import *  # noqa

{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
# S3 Storage for media files
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
AWS_STORAGE_BUCKET_NAME = env('AWS_STORAGE_BUCKET_NAME', default='{{ cookiecutter.project_slug }}-media')
AWS_S3_REGION_NAME = env('AWS_REGION', default='{{ cookiecutter.aws_region }}')
AWS_DEFAULT_ACL = 'public-read'
AWS_S3_FILE_OVERWRITE = False
AWS_LOCATION = 'media/'
AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'

# RDS connection
# The DATABASE_URL should be set via Secrets Manager in App Runner
# Format: postgres://user:password@host:5432/dbname

# Trust App Runner's proxy headers
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# App Runner sets PORT environment variable
import os
PORT = int(os.environ.get('PORT', 8000))
{% endif -%}
