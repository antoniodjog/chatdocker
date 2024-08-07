# Etapa 1: Construir la aplicación React
FROM node:18 AS build

WORKDIR /app

# Copiar el frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm install

COPY frontend ./
RUN npm run build

# Etapa 2: Configurar y construir la aplicación Django
FROM python:3.11 AS backend

WORKDIR /app

# Copiar el backend
COPY chatbot_forecast/requirements.txt ./
RUN pip install -r requirements.txt

COPY chatbot_forecast/ ./


# Etapa 3: Configurar Nginx y Gunicorn
FROM nginx:latest

# Copiar el contenido estático de React al contenedor de Nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Copiar la configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar los archivos de Django al contenedor
COPY --from=backend /app /app

# Configurar Gunicorn para que se ejecute como un socket
COPY docker/gunicorn.socket /etc/systemd/system/gunicorn.socket
COPY docker/gunicorn.service /etc/systemd/system/gunicorn.service

# Exponer el puerto en el que Nginx escuchará
EXPOSE 80

# Iniciar Nginx y Gunicorn
CMD ["sh", "-c", "nginx -g 'daemon off;' && gunicorn --config /app/gunicorn_config.py chatbot_forecast.wsgi:application"]
