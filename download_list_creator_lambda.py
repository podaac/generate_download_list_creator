"""Download List Creator Lambda

This script serves as a wrapper to the original download list creator code.
It performs the following:
1. Determine arguments from event payload.
2. Call cshell script with arguments.
3. Get text file name(s) from log file.
4. Upload text file(s) to S3 bucket.
5. Push text file name(s) to queue.

Notes:
- Include year so that we don't have to change each year for the daily execution of Generate
- If reprocessing make sure not to use the GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE indicator argument and to set start and end dates
"""

# Standard imports
import datetime
import json
import logging
import os
import pathlib
import random
import subprocess
from subprocess import PIPE
import sys

# Third-party imports
import boto3
import botocore

# Local imports
from notify import notify

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

UNIQUE_ID = random.randint(1000, 9999)    # To differentiate duplicate txt file names

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
    naming_pattern_indicator = event["naming_pattern_indicator"] if "naming_pattern_indicator" in event.keys() else ""
    if granule_start_date == "dummy" and granule_end_date == "dummy": 
        year = f"{datetime.datetime.now().year}"
    else:
        year = "-1"
        naming_pattern_indicator = ""
    txt_file_list = pathlib.Path("/tmp/txt_file_list.txt")
    
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
    try:
        subprocess.run([f"{lambda_task_root}/shell/startup_generic_download_list_creator.csh", \
            search_pattern, output_directory, processing_type, processing_level, \
            state_file_name, num_days_back, txt_file_list, year, \
            granule_start_date, granule_end_date, naming_pattern_indicator], \
            cwd=f"{lambda_task_root}/shell", check=True, stderr=PIPE)
    except subprocess.CalledProcessError as e:
        sigevent_description = e.stderr.decode("utf-8").strip()
        sigevent_data = f"Subprocess Run command: {e.cmd}"
        handle_error(sigevent_description, sigevent_data, logger)
    
    # Get list of text file name(s)
    if txt_file_list.exists():
        with open(txt_file_list) as fh:
            txt_list = fh.read().splitlines()
        txt_list = [output_directory.joinpath(txt) for txt in txt_list]
    else:
        txt_list = []
    logger.info(txt_list)
    
    # Check pending jobs queue
    sqs = boto3.client("sqs")
    sqs_queue_pj = f"https://sqs.{event['region']}.amazonaws.com/{event['account']}/{event['prefix']}-pending-jobs"
    pending_txts = check_queue(sqs, sqs_queue_pj, DS_KEY[processing_type], logger)
    
    if len(txt_list) != 0 or len(pending_txts) != 0:
        
        if len(txt_list) != 0: 
            # Upload txt files to S3 bucket
            upload_text_files(s3_client, txt_list, bucket, DS_KEY[processing_type], logger)
            
            # Upload state file to S3 bucket
            upload_state_file(s3_client, state_file_name, bucket, logger)
            
            # Delete files
            delete_files(txt_list, state_file_name, txt_file_list, logger)
            
        # Push list of txt files to SQS queue
        sqs_queue_dl = f"https://sqs.{event['region']}.amazonaws.com/{event['account']}/{event['prefix']}-download-lists"
        txt_files = [f"{txt_file.name}_{UNIQUE_ID}" for txt_file in txt_list]
        txt_files.extend(pending_txts)
        send_text_file_list(sqs, txt_files, sqs_queue_dl, event['prefix'], DS_KEY[processing_type], logger)
        
    else:
        logger.info("No new downloads were found.")
    
    # Delete logger    
    for handler in logger.handlers:
        logger.removeHandler(handler) 
    
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
            sigevent_description = f"Problem retrieving state file {state_file_name.name}."
            handle_error(sigevent_description, e, logger)
            
def check_queue(sqs, sqs_queue, dataset, logger):
    """Check queue to see if there are any downloads from previous executions.
    
    Returns list of text files that contain downloads.
    """
    
    # Read in queue nessages
    try:
        messages = sqs.receive_message(
            QueueUrl=sqs_queue,
            AttributeNames=["All"],
            MessageAttributeNames=["dataset"],
            MaxNumberOfMessages=10
        )
        
        # Create list of messages for dataset
        dlc_list = []
        for message in messages["Messages"]:
            if message["MessageAttributes"]["dataset"]["StringValue"] == dataset:
                dlc_list.extend(json.loads(message["Body"]))
                # Delete message
                response = sqs.delete_message(
                    QueueUrl=sqs_queue,
                    ReceiptHandle=message["ReceiptHandle"]
                )
                logger.info(f"Found pending job(s): {message['Body']}")           
                    
    except botocore.exceptions.ClientError as e:
        sigevent_description = "Problem checking queue for pending jobs."
        handle_error(sigevent_description, e, logger)

    except KeyError as e:
        logger.info("No pending jobs found.")
    
    return list(set(dlc_list))

def get_text_file_names(txt_file_list):
    """Retrieve a list of text file names from the text file."""
    
    with open(txt_file_list) as fh:
        txt_list = fh.read().splitlines()
    return txt_list

def upload_text_files(s3_client, txt_files, bucket, key, logger):
    """Upload text files to S3 bucket."""
    
    try:
        for txt_file in txt_files:
            response = s3_client.upload_file(str(txt_file), bucket, f"{key}/{txt_file.name}_{UNIQUE_ID}", ExtraArgs={"ServerSideEncryption": "aws:kms"})
            logger.info(f"File uploaded: {key}/{txt_file.name}_{UNIQUE_ID}")
    except botocore.exceptions.ClientError as e:
        txt_list = [ txt_file.name for txt_file in txt_files ]
        sigevent_description = f"Problem uploading text files: {', '.join(txt_list)}."
        handle_error(sigevent_description, e, logger)

def send_text_file_list(sqs, txt_files, sqs_queue, prefix, dataset, logger):
    """Send comma separated list of text files to SQS queue."""
    
    out_dict = {
        "prefix": prefix,
        "dataset": dataset,
        "txt_list": txt_files
    }
    try:
        response = sqs.send_message(
            QueueUrl=sqs_queue,
            MessageBody=json.dumps(out_dict)
        )
        logger.info(f"Sent following list to download lists queue: {', '.join(out_dict['txt_list'])}")
    except botocore.exceptions.ClientError as e:
        sigevent_description = f"Problem sending file list to downloads list queue: {', '.join(out_dict['txt_list'])}."
        handle_error(sigevent_description, e, logger)
        
def upload_state_file(s3_client, state_file, bucket, logger):
    """Upload state file to S3 bucket."""
    
    try:
        response = s3_client.upload_file(str(state_file), bucket, f"state_files/{state_file.name}", ExtraArgs={"ServerSideEncryption": "aws:kms"})
        logger.info(f"File uploaded: state_files/{state_file.name}")
    except botocore.exceptions.ClientError as e:       
        sigevent_description = f"Problem uploading state file: {state_file.name}."
        handle_error(sigevent_description, e, logger)
        
def delete_files(txt_list, state_file_name, txt_file_list, logger):
    """Delete files created in /tmp directory and remove logging handlers."""
    
    for txt in txt_list:
        txt.unlink()
        logger.info(f"Deleted file: {txt.name}")
    
    state_file_name.unlink()
    logger.info(f"Deleted file: {state_file_name.name}")
    
    txt_file_list.unlink()
    logger.info(f"Deleted file: {txt_file_list.name}")
        
def handle_error(sigevent_description, sigevent_data, logger):
    """Handle errors by logging them and sending out a notification."""
    
    sigevent_type = "ERROR"
    logger.error(sigevent_description)
    logger.error(sigevent_data)
    notify(logger, sigevent_type, sigevent_description, sigevent_data)
    logger.error("Program exit.")
    sys.exit(1)