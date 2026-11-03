# Use NGINX Alpine as the lightweight web server
FROM nginx:alpine

# Copy your index.html into NGINX's public directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Run NGINX
CMD ["nginx", "-g", "daemon off;"]