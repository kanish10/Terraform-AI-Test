## KNOWLEDGE BASE

# FOR GCP:

1. Enable Prevent Public Access (GCS)
2. Bucket delete lifecycle for deletion
    2.1 If "sec_Assets_public: y" then it must set deleted after setting the object retention period. If it is "y" then it contains sensitive data
3. Mandatory labels for GCS bucket:
    3.1 "sec_assets": data description
    3.2 "sec_assets_pii": y if including pii data, n if not
    3.3 "sec_assets_public": y if public, n means private
    3.4 "sec_logs": activity, data access, storage bucket access
4. Logging and monitoring:
    4.1 Admin activity log needs to stored for more than 1 year
    4.2 Data access log must stored for more than 1 year, but if it contains pii data then it needs to be more than 2 years
5. For every GCS bucket it needs to be configured for access log configuration to the access log bucket. The destination log access bucket should have a tag "sec_log": "storage_bucket_access"