WITH    backupsetSummary
          AS ( SELECT   bs.database_name ,
                        bs.type bstype ,
                        MAX(backup_finish_date) MAXbackup_finish_date
               FROM     msdb.dbo.backupset bs
               GROUP BY bs.database_name ,
                        bs.type
             ),
        MainBigSet
          AS ( SELECT   
						@@SERVERNAME servername,
						db.name ,
                        db.state_desc ,
                        db.recovery_model_desc ,
                        bs.type ,
                        convert(decimal(10,2),bs.backup_size/1024.00/1024) backup_sizeinMB,
						bs.backup_start_date,
                        bs.backup_finish_date,
						physical_device_name,
						DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS DurationMins
			            FROM     master.sys.databases db
                        LEFT OUTER JOIN backupsetSummary bss ON bss.database_name = db.name
                        LEFT OUTER JOIN msdb.dbo.backupset bs ON bs.database_name = db.name
                                                              AND bss.bstype = bs.type
                                                              AND bss.MAXbackup_finish_date = bs.backup_finish_date
						JOIN msdb.dbo.backupmediafamily m ON bs.media_set_id = m.media_set_id
						where  db.database_id>4
             )
 
			-- select * from MainBigSet
 
SELECT
	servername,
	name,
	state_desc,
	recovery_model_desc,
	Last_Backup      = MAX(a.backup_finish_date),  
	Last_Full_Backup_start_Date = MAX(CASE WHEN A.type='D' 
										THEN a.backup_start_date ELSE NULL END),
	Last_Full_Backup_end_date = MAX(CASE WHEN A.type='D' 
										THEN a.backup_finish_date ELSE NULL END),
	Last_Full_BackupSize_MB=  MAX(CASE WHEN A.type='D' THEN backup_sizeinMB  ELSE NULL END),
	DurationSeocnds = MAX(CASE WHEN A.type='D' 
										THEN DATEDIFF(SECOND, a.backup_start_date, a.backup_finish_date) ELSE NULL END),
	Last_Full_Backup_path = MAX(CASE WHEN A.type='D' 
										THEN a.physical_Device_name ELSE NULL END),
	Last_Diff_Backup_start_Date = MAX(CASE WHEN A.type='I' 
										THEN a.backup_start_date ELSE NULL END),
	Last_Diff_Backup_end_date = MAX(CASE WHEN A.type='I' 
										 THEN a.backup_finish_date ELSE NULL END),
	Last_Diff_BackupSize_MB=  MAX(CASE WHEN A.type='I' THEN backup_sizeinMB  ELSE NULL END),
	DurationSeocnds = MAX(CASE WHEN A.type='I' 
										THEN DATEDIFF(SECOND, a.backup_start_date, a.backup_finish_date) ELSE NULL END),
	Last_Log_Backup_start_Date = MAX(CASE WHEN A.type='L' 
										THEN a.backup_start_date ELSE NULL END),
	Last_Log_Backup_end_date = MAX(CASE WHEN A.type='L' 
										 THEN a.backup_finish_date ELSE NULL END),
	Last_Log_BackupSize_MB=  MAX(CASE WHEN A.type='L' THEN backup_sizeinMB  ELSE NULL END),
	DurationSeocnds = MAX(CASE WHEN A.type='L' 
										THEN DATEDIFF(SECOND, a.backup_start_date, a.backup_finish_date) ELSE NULL END),
	Last_Log_Backup_path = MAX(CASE WHEN A.type='L' 
										THEN a.physical_Device_name ELSE NULL END),
	[Days_Since_Last_Backup] = DATEDIFF(d,(max(a.backup_finish_Date)),GETDATE())
FROM
	MainBigSet a
group by 
	 servername,
	 name,
	 state_desc,
	 recovery_model_desc
--	order by name,backup_start_date desc