BACKUP LOG [Account] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [Docusign] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [DocusignAPILog] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [Quartz] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [PubSub] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [DocuSignCentral] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [EnvelopeSearch] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [EnvelopePartition_01001] TO DISK = 'nul:' WITH STATS = 10;
BACKUP LOG [EnvelopePartition_01002] TO DISK = 'nul:' WITH STATS = 10;


DBCC SQLPERF(LOGSPACE)

