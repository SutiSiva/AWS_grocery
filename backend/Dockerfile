# --- Base Image ---
FROM python:3.11-slim

# --- Arbeitsverzeichnis im Container ---
WORKDIR /app

# --- Systemabhängigkeiten installieren ---
RUN apt-get update && apt-get install -y \
    libpq-dev gcc && \
    pip install --upgrade pip

# --- Anforderungen installieren ---
COPY requirements.txt .
RUN pip install -r requirements.txt

# --- Projektdateien kopieren ---
COPY . .

# --- Environment Variables (optional defaults) ---
ENV FLASK_APP=run.py
ENV FLASK_ENV=production
ENV USE_S3_STORAGE=true

# --- Port öffnen ---
EXPOSE 5000

# --- Startbefehl ---
CMD ["python", "run.py"]
