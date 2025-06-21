## Dokumentasi Penggunaan Environment dan Volume

### Environment Variables

Anda dapat mengatur environment variables pada container ini untuk menyesuaikan konfigurasi PHP atau aplikasi Anda. Contoh penggunaan environment variable pada `docker run`:

Beberapa environment variable umum:
# System timezone
      - TZ=Asia/Jakarta
      
      # PHP Configuration
      - PHP_MEMORY_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=180
      - PHP_POST_MAX_SIZE=50M
      - PHP_UPLOAD_MAX_FILESIZE=20M
      - PHP_MAX_INPUT_VARS=3000
      - PHP_DATE_TIMEZONE=Asia/Jakarta
      - PHP_DISPLAY_ERRORS=On
      - PHP_LOG_ERRORS=On
      - PHP_ERROR_REPORTING=E_ALL

### Volume

Volume digunakan untuk menyimpan data secara persisten atau menghubungkan file konfigurasi dari host ke container.

Contoh mounting volume saat menjalankan container:

```sh
docker run -v /path/host:/path/container ...
```

Contoh penggunaan:
- Mount direktori aplikasi:
    ```sh
    docker run -v $(pwd)/src:/var/www/html ...
    ```

Pastikan path pada host sudah benar dan memiliki izin akses yang sesuai.
