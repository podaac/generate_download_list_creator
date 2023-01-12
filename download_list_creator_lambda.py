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
import json
import logging
import os
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

DS_KEY = {
    "MODIS_A": "aqua",
    "MODIS_T": "terra",
    "VIIRS": "viirs"
}

def event_handler(event, context):
    """Parse EventBridge schedule event for arguments and run the list creator."""
    
    start = datetime.datetime.now()
    
    # Arguments
    search_pattern = event["search_pattern"]
    output_directory = pathlib.Path("/tmp/generate_output")
    processing_type = event["processing_type"]
    processing_level = event["processing_level"]
    state_file_name = pathlib.Path(f"/tmp/generate_state_file/{processing_type.lower()}.txt")
    num_days_back = event["num_days_back"]
    granule_start_date = event["granule_start_date"]
    granule_end_date = event["granule_end_date"]
    naming_pattern_indicator = event["naming_pattern_indicator"]
    
    # Create required directories
    if not output_directory.is_dir():
        output_directory.mkdir(parents=True, exist_ok=True)
    if not state_file_name.parent.is_dir():
        state_file_name.parent.mkdir(parents=True, exist_ok=True)
        
    # Check if state file exists and pull from S3 to /tmp if it does
    s3_client = boto3.client("s3")
    bucket = f"{event['prefix']}-download-lists"
    logger = get_logger()
    get_s3_state_file(s3_client, bucket, state_file_name, logger)
        
    # Execute shell script
    lambda_task_root = os.getenv('LAMBDA_TASK_ROOT')
    subprocess.run([f"{lambda_task_root}/shell/startup_generic_download_list_creator.csh", \
        search_pattern, output_directory, processing_type, processing_level, \
        state_file_name, num_days_back, granule_start_date, granule_end_date, \
        naming_pattern_indicator], cwd=f"{lambda_task_root}/shell")
    
    # Get list of text file name(s)
    tz = pytz.timezone("America/Los_Angeles")
    today = datetime.datetime.now(tz).strftime("%m_%d_%y_%H")
    digits_in_name = "0001"
    log_file = pathlib.Path("/tmp/generate_logs").joinpath(f"{LOG_PREFIX[processing_type]}_{today}*_list_{digits_in_name}.log")
    log_file = glob.glob(str(log_file))[0]
    txt_list = get_text_file_names(log_file)

    if len(txt_list) != 0:
        # Upload txt files to S3 bucket
        upload_text_files(s3_client, txt_list, bucket, DS_KEY[processing_type], logger)
        
        # Push list of txt files to SQS queue
        sqs_queue = f"https://sqs.{event['region']}.amazonaws.com/{event['account']}/{event['prefix']}-download-lists"
        send_text_file_list(txt_list, sqs_queue, event['prefix'], DS_KEY[processing_type], logger)
        
        # Upload state file to S3 bucket
        upload_state_file(s3_client, state_file_name, bucket, logger)
        
        # Delete files
        delete_files(txt_list, state_file_name, log_file, logger)
    else:
        logger.info("No new downloads were found.")
    
    end = datetime.datetime.now()
    logger.info(f"Execution time - {end - start}.")
    
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

def get_s3_state_file(s3_client, bucket, state_file_name, logger):
    """Retrieve state file from S3 bucket if it exists."""
    
    try:
        response = s3_client.download_file(bucket, f"state_files/{state_file_name.name}", str(state_file_name))
        logger.info(f"State file copied: {state_file_name}")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "404":
            logger.info(f"State file does not exist: state_files/{state_file_name.name}")
        else:
            logger.error("Problem retrieving state file.")
            logger.error(e)
            logger.error("Program exit.")
            exit(1)

def get_text_file_names(log_file):
    """Retrieve a list of text file names from the log file."""
    
    with open(log_file) as fh:
        log_data = fh.read().splitlines()
    txt_list = []
    for d in log_data: 
        if d.strip().startswith("/tmp/generate_output"): 
            txt_list.append(pathlib.Path(d.strip().split(' ')[0]))
    return txt_list

def upload_text_files(s3_client, txt_files, bucket, key, logger):
    """Upload text files to S3 bucket."""
    
    try:
        for txt_file in txt_files:
            response = s3_client.upload_file(str(txt_file), bucket, f"{key}/{txt_file.name}", ExtraArgs={"ServerSideEncryption": "aws:kms"})
            logger.info(f"File uploaded: {key}/{txt_file.name}")
    except botocore.exceptions.ClientError as e:
        logger.error("Problem uploading text files.")
        logger.error(e)
        logger.error("Program exit.")
        exit(1)

def send_text_file_list(txt_files, sqs_queue, prefix, dataset, logger):
    """Send comma separated list of text files to SQS queue."""
    
    out_dict = {
        "prefix": prefix,
        "dataset": dataset,
        "txt_list": [txt_file.name for txt_file in txt_files]
    }
    sqs = boto3.client("sqs")
    try:
        response = sqs.send_message(
            QueueUrl=sqs_queue,
            MessageBody=json.dumps(out_dict)
        )
        logger.info(f"Sent following list to queue: {', '.join(out_dict['txt_list'])}")
    except botocore.exceptions.ClientError as e:
        logger.error("Problem sending file list to queue.")
        logger.error(e)
        logger.error("Program exit.")
        exit(1)
        
def upload_state_file(s3_client, state_file, bucket, logger):
    """Upload state file to S3 bucket."""
    
    try:
        response = s3_client.upload_file(str(state_file), bucket, f"state_files/{state_file.name}", ExtraArgs={"ServerSideEncryption": "aws:kms"})
        logger.info(f"File uploaded: state_files/{state_file.name}")
    except botocore.exceptions.ClientError as e:
        logger.error("Problem uploading state file.")
        logger.error(e)
        logger.error("Program exit.")
        exit(1)
        
def delete_files(txt_list, state_file_name, log_file, logger):
    """Delete files created in /tmp directory."""
    
    for txt in txt_list:
        txt.unlink()
    state_file_name.unlink()
    pathlib.Path(log_file).unlink()
    
    txt_list = [str(txt) for txt in txt_list]
    logger.info(f"Deleted the following files: {', '.join(txt_list)}, {state_file_name.name}, {pathlib.Path(log_file).name}")