FROM python:3.9-slim AS connect-four-deployment
# Use the official Nginx image as base image
FROM nginx:alpine

# Set the working directory in the container
WORKDIR /usr/share/nginx/html

# Remove the default index.html
RUN rm -f index.html

COPY Part3_FrontEndProject.html index.html
COPY Part3_FrontEndProject.css .
COPY Part3_FrontEndProject.js .

# Expose port 80
EXPOSE 5000

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
