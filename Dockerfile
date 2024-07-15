FROM node:latest AS node-setup
WORKDIR /setup
COPY . .
RUN npm install -g less && \
    npm install -g typescript && \
    cd client && \
    npm install && \
    npm run build && \
    cd ..

FROM python:3.8 AS production
WORKDIR /usr/src/app
COPY --from=node-setup /setup .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--env-file", "./.env", "--port", "8000"]