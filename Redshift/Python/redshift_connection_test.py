# Import packages
import logging
import boto3
import redshift_connector
import getpass
import os
from botocore.exceptions import BotoCoreError, NoCredentialsError, PartialCredentialsError, ClientError


# ****************************************
# variables - Update me!!!
# ****************************************
host_name = "redshift host" #AWS host/url Provide for User/Password connections
region = "" #AWS region where the host lives
cluster_identifier="" #AWS Provide for IAM connections
host_port = 5439 # port where redshift is listening 5439 is the default port
db_name = "dev"  # Database to connect to initially
db_user = "changeme"  # Database user name, used to connect to
use_autocommit = True  # This should stay true
credential_type = "iam"  # can be either "iam" or "db"

#Logging colors
class ColoredFormatter(logging.Formatter):
    def format(self, record):
        if record.levelno == logging.WARNING:
            record.msg = "\033[93m%s\033[0m" % record.msg
        elif record.levelno == logging.ERROR:
            record.msg = "\033[91m%s\033[0m" % record.msg
        elif record.levelno == logging.INFO:
            record.msg = "\033[94m%s\033[0m" % record.msg
        return logging.Formatter.format(self, record)

# Configure logging
logger = logging.getLogger("mylogger")
handler = logging.StreamHandler()
log_format = "%(levelname)s - %(message)s"
time_format = "%H:%M:%S"
formatter = ColoredFormatter(log_format, datefmt=time_format)
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

def get_redshift_connection(
    host_name = "redshift.amazonaws.com",
    host_port = 5439,
    cluster_identifier = "",
    region = "",
    db_user = "someuser",
    db_name = "dev",
    use_autocommit = True,
    conn = None,
    credential_type = "iam",
    access_key_id = None,
    secret_access_key = None,
):

    logger.info(
        f"-- Establishing Redshift connection using {credential_type} credentials"
    )
    if conn:
        # use existing
        return conn

    if credential_type == "iam":
        try:
            #creds = get_iam_credentials()
            #if creds is None:
                #return None
        
            conn = redshift_connector.connect(
                iam=True,
                database=db_name,
                db_user=db_user,
                cluster_identifier=cluster_identifier,
                region=region,
                access_key_id=access_key_id,
                secret_access_key=secret_access_key
                )
            
            if use_autocommit:
                conn.autocommit = True

            logger.info(f"-- Connected to redshift as user: {db_user}")
            logger.info(f"-- Connected to redshift database: {db_name}")

        except (redshift_connector.Error, BotoCoreError, NoCredentialsError, PartialCredentialsError, ClientError) as e:
            # If the connection failed, print the error message
            logger.error(f"-- Connection failed for {db_user}: {e}")
            raise SystemExit(1)
        
    elif credential_type == "db":
        try:
            conn = redshift_connector.connect(
                host=host_name,
                database=db_name,
                user=db_user,
                password=getpass.getpass(),
                port=host_port
                )
            
            if use_autocommit:
                conn.autocommit = True

            logger.info(f"-- Connected to redshift as user: {db_user}")
            logger.info(f"-- Connected to redshift database: {db_name}")

        except redshift_connector.InterfaceError as e:
            # If the connection failed, print the error message
            logger.error(f"-- Connection failed: {e}")
            raise SystemExit(1)
    else:
        raise ValueError('credential_type must be "iam" or "db"')
    
    return conn

# Workflow starts here
if __name__ == "__main__":
    os.system("clear")
    logger.info("Starting - Connection_test.py")

    get_redshift_connection(
        host_name = host_name,
        host_port = host_port,
        cluster_identifier = cluster_identifier,
        region = region,
        db_user = db_user,
        db_name = db_name,
        use_autocommit = use_autocommit,
        credential_type = credential_type)

    logger.info("Completed - Connection_test.py")
