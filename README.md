# sync-all-blobs-from-az-storage
A script that syncs all blobs from an Azure Storage account

You could execute this on a schedule and log its output to a file with a cron job like:

```bash
{
intervalInMinutes=5
echo "*/$intervalInMinutes * * * * /home/azureuser/sync-from-storage.sh $3 $4 >> /home/azureuser/sync-from-storage.log 2>&1" > syncJob && crontab syncJob
}
```
