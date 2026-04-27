DAY 2 - linux permissions, users, processes, services, logs
1. Learned file permissions and chmod
2. Created users and groups
3. Installed and controlled Nginx with systemctl
4. Read and searched log files with tail, grep and awk

NOtes: Permissions have 3 parts- owner, group, others
chmod removes all permissions even the owner's 
users are isolated and can't access each other's folders/files.
 systemctl start/stop/enable/status controls services
 tail -20 shows last 20 lines of a file
 grep searches for a pattern inside a file
 awk extracts specific columns from text