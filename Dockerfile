FROM ubuntu:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# System timezone configuration
ENV TZ=UTC

# Default PHP configuration via environment variables
ENV PHP_MEMORY_LIMIT=128M
ENV PHP_MAX_EXECUTION_TIME=30
ENV PHP_POST_MAX_SIZE=8M
ENV PHP_UPLOAD_MAX_FILESIZE=2M
ENV PHP_MAX_INPUT_VARS=1000
ENV PHP_DATE_TIMEZONE=UTC
ENV PHP_DISPLAY_ERRORS=Off
ENV PHP_LOG_ERRORS=On
ENV PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT"
ENV CONF_FILE="/etc/apache2/conf-enabled/security.conf"

# Install software-properties-common to add PPAs
RUN apt-get update && apt-get install -y \
    software-properties-common \
    nano \
    tzdata \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update

# Install Apache and PHP 7.0 from the PPA
RUN apt-get install -y \
    apache2 \
    php7.0 \
    php7.0-cli \
    php7.0-mysql \
    php7.0-xml \
    php7.0-gd \
    php7.0-curl \
    php7.0-mbstring \
    php7.0-zip \
    php7.0-intl \
    php7.0-bcmath \
    libapache2-mod-php7.0 \
    wget \
    unzip \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite \
    && a2enmod headers

RUN sed -i '/^ServerTokens/d' "$CONF_FILE" && \
    sed -i '1iServerTokens Prod' "$CONF_FILE" 

RUN a2dissite 000-default

RUN  tee /etc/apache2/sites-available/default.conf <<EOF
<VirtualHost *:80>
  ServerName localhost
  DirectoryIndex index.php index.html
  DocumentRoot /var/www/html 
  
  ServerSignature Off

  <IfModule mod_headers.c>
    #Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "no-referrer-when-downgrade"
    # Contoh untuk CORS (sesuaikan dengan kebutuhan Anda)
    # Header set Access-Control-Allow-Origin "*"
  </IfModule>

  <Directory /var/www/html>
    Options +FollowSymlinks -Indexes
    AllowOverride All
    Require all granted

    SetEnv HOME /var/www/html
    SetEnv HTTP_HOME /var/www/html
  </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

RUN a2ensite default.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install ionCube Loader
RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xzf ioncube_loaders_lin_x86-64.tar.gz \
    && PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');") \
    && mv ioncube/ioncube_loader_lin_7.0.so $PHP_EXT_DIR \
    && echo "zend_extension=$PHP_EXT_DIR/ioncube_loader_lin_7.0.so" > /etc/php/7.0/apache2/conf.d/00-ioncube.ini \
    && echo "zend_extension=$PHP_EXT_DIR/ioncube_loader_lin_7.0.so" > /etc/php/7.0/cli/conf.d/00-ioncube.ini \
    && rm -rf ioncube*

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Set system timezone' >> /start.sh && \
    echo 'if [ ! -z "$TZ" ]; then' >> /start.sh && \
    echo '    echo "Setting system timezone to: $TZ"' >> /start.sh && \
    echo '    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime' >> /start.sh && \
    echo '    echo $TZ > /etc/timezone' >> /start.sh && \
    echo '    dpkg-reconfigure -f noninteractive tzdata' >> /start.sh && \
    echo '    if [ "$PHP_DATE_TIMEZONE" = "UTC" ] && [ "$TZ" != "UTC" ]; then' >> /start.sh && \
    echo '        export PHP_DATE_TIMEZONE=$TZ' >> /start.sh && \
    echo '        echo "Auto-setting PHP timezone to: $TZ"' >> /start.sh && \
    echo '    fi' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Generate PHP configuration' >> /start.sh && \
    echo 'cat > /etc/php/7.0/apache2/conf.d/99-custom.ini << EOF' >> /start.sh && \
    echo '; Custom PHP Configuration from Environment Variables' >> /start.sh && \
    echo 'memory_limit = ${PHP_MEMORY_LIMIT}' >> /start.sh && \
    echo 'max_execution_time = ${PHP_MAX_EXECUTION_TIME}' >> /start.sh && \
    echo 'post_max_size = ${PHP_POST_MAX_SIZE}' >> /start.sh && \
    echo 'upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}' >> /start.sh && \
    echo 'max_input_vars = ${PHP_MAX_INPUT_VARS}' >> /start.sh && \
    echo 'date.timezone = ${PHP_DATE_TIMEZONE}' >> /start.sh && \
    echo 'display_errors = ${PHP_DISPLAY_ERRORS}' >> /start.sh && \
    echo 'log_errors = ${PHP_LOG_ERRORS}' >> /start.sh && \
    echo 'error_reporting = ${PHP_ERROR_REPORTING}' >> /start.sh && \
    echo 'EOF' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Copy PHP config for CLI' >> /start.sh && \
    echo 'cp /etc/php/7.0/apache2/conf.d/99-custom.ini /etc/php/7.0/cli/conf.d/99-custom.ini' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Create document root if it does not exist' >> /start.sh && \
    echo 'mkdir -p /var/www/html' >> /start.sh && \
    echo 'chown -R www-data:www-data /var/www/html' >> /start.sh && \
    echo 'chmod -R 755 /var/www/html' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Display configuration info' >> /start.sh && \
    echo 'echo "System timezone: $(cat /etc/timezone 2>/dev/null || echo UTC)"' >> /start.sh && \
    echo 'echo "PHP timezone: ${PHP_DATE_TIMEZONE}"' >> /start.sh && \
    echo 'echo "PHP memory limit: ${PHP_MEMORY_LIMIT}"' >> /start.sh && \
    echo 'echo "Current time: $(date)"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Apache in foreground' >> /start.sh && \
    echo 'exec apachectl -D FOREGROUND' >> /start.sh

# Make startup script executable
RUN chmod +x /start.sh

# Set up Apache's DocumentRoot
RUN rm -rf /var/www/html && mkdir -p /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

WORKDIR /var/www/html

# Expose port 80 for Apache
EXPOSE 80

# Use startup script
CMD ["/start.sh"]