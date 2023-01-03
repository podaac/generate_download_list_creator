"""Download List Creator Lambda

This script serves as a wrapper to the original download list creator code.
It performs the following:
1. Determine arguments from event payload.
2. Call cshell script with arguments.
3. Get text file name(s) from log file.
4. Upload text file(s) to S3 bucket.
5. Push text file name(s) to queue.
"""

# Standard imports
import datetime
import glob
import logging
import pathlib
import subprocess

# Third-party imports
import pytz
import boto3
import botocore

# Constants
LOG_PREFIX = {
    "MODIS_A": "modis_level2_aqua_MODIS_A_download_list_creator_output",
    "MODIS_T": "modis_level2_terra_MODIS_T_download_list_creator_output",
    "VIIRS": "viirs_level2_VIIRS_download_list_creator_output"
}

def event_handler(event, context):
    """Parse EventBridge schedule event for arguments and run the list creator."""
    
    start = datetime.datetime.now()
    
    # Arguments
    search_pattern = event["search_pattern"]
    output_directory = pathlib.Path("/tmp/generate_output")
    processing_type = event["processing_type"]
    processing_level = event["processing_level"]
    state_file_name = pathlib.Path(f"/tmp/generate_state_file/{event['processing_type'].lower()}.txt")
    num_days_back = event["num_days_back"]
    granule_start_date = event["granule_start_date"]
    granule_end_date = event["granule_end_date"]
    naming_pattern_indicator = event["naming_pattern_indicator"]
    bucket = event["s3_bucket"]
    sqs_queue = event["sqs_queue"]
    
    # Create required directories
    if not output_directory.is_dir():
        output_directory.mkdir(parents=True, exist_ok=True)
    if not state_file_name.parent.is_dir():
        state_file_name.parent.mkdir(parents=True, exist_ok=True)
        
    # Execute shell script
    subprocess.run(["/home/tebaldi/generate/workspace/generate/download_list_creator/shell/startup_generic_download_list_creator.csh", \
        search_pattern, output_directory, processing_type, processing_level, \
        state_file_name, num_days_back, granule_start_date, granule_end_date, \
        naming_pattern_indicator], cwd="/home/tebaldi/generate/workspace/generate/download_list_creator/shell")   # TODO Change to LAMBDA ROOT TASK ENV VAR
    
    # Get list of text file name(s)
    tz = pytz.timezone("America/Los_Angeles")
    today = datetime.datetime.now(tz).strftime("%m_%d_%y_%H")
    digits_in_name = "0001"
    log_file = pathlib.Path("/tmp/generate_logs").joinpath(f"{LOG_PREFIX[processing_type]}_{today}*_list_{digits_in_name}.log")
    txt_list = get_text_file_names(log_file)
    
    # Get logger
    logger = get_logger()
    
    # Upload txt files to S3 bucket
    upload_text_files(txt_list, bucket, logger)
    
    # Push list of txt files to SQS queue
    send_text_file_list(txt_list, sqs_queue, logger)
    
def get_text_file_names(log_file):
    """Retrieve a list of text file names from the log file."""
    
    log_file = glob.glob(str(log_file))[0]
    with open(log_file) as fh:
        log_data = fh.read().splitlines()
    txt_list = []
    for d in log_data: 
        if d.strip().startswith("/tmp/generate_output"): 
            txt_list.append(pathlib.Path(d.strip().split(' ')[0]))
    return txt_list

def get_logger():
    """Return a formatted logger object."""
    
    # Remove AWS Lambda logger
    logger = logging.getLogger()
    for handler in logger.handlers:
        logger.removeHandler(handler)
    
    # Create a Logger object and set log level
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # Create a handler to console and set level
    console_handler = logging.StreamHandler()

    # Create a formatter and add it to the handler
    console_format = logging.Formatter("%(asctime)s - %(module)s - %(levelname)s : %(message)s")
    console_handler.setFormatter(console_format)

    # Add handlers to logger
    logger.addHandler(console_handler)

    # Return logger
    return logger

def upload_text_files(txt_files, bucket, logger):
    """Upload text files to S3 bucket."""
    
    session = boto3.Session(profile_name="podaac-sandbox")
    s3 = session.client("s3")
    try:
        for txt_file in txt_files:
            response = s3.upload_file(str(txt_file), bucket, txt_file.name)
            logger.info(f"File uploaded: {txt_file.name}")
    except botocore.exceptions.ClientError as e:
        logger.error(e)
        logger.error("Program exit.")
        exit(1)

def send_text_file_list(txt_files, sqs_queue, logger):
    """Send comma separated list of text files to SQS queue."""
    
    txt_list = [txt_file.name for txt_file in txt_files]
    
    session = boto3.Session(profile_name="podaac-sandbox")
    sqs = session.client("sqs")
    try:
        response = sqs.send_message(
            QueueUrl=sqs_queue,
            MessageBody=', '.join(txt_list)
        )
        logger.info(f"Sent following list to queue: {', '.join(txt_list)}")
    except botocore.exceptions.ClientError as e:
        logger.error(e)
        logger.error("Program exit.")
        exit(1)