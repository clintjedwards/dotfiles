### Backup NAS to google cloud

`gsutil -m -o GSUtil:parallel_composite_upload_threshold=150M cp -L /tmp/uploadlog -r /data gs://production-161206-cold-backups/`
