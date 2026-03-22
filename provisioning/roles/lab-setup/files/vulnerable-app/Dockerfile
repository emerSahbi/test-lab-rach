# Dockerfile — deliberately uses an old base image so Trivy finds CVEs
# FOR SAST TRAINING PURPOSES ONLY — do not use in production.

FROM python:3.9-slim-bullseye

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Running as root (container security smell — no USER instruction)
EXPOSE 5000
CMD ["python", "app.py"]
