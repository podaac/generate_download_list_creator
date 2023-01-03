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
    
def get_text_file_names(log_file):
    """Retrieve a list of text file names from the log file."""
    
    log_file = glob.glob(str(log_file))[0]
    with open(log_file) as fh:
        log_data = fh.read().splitlines()
    txt_list = []
    for d in log_data: 
        if d.strip().startswith("/tmp/generate_output"): 
            txt_list.append(d.strip().split(' ')[0])
    return txt_list

def upload_txt_files(txt_files):
    """Upload text files to S3 bucket."""
    
    

if __name__ == "__main__":
    event = {
        "search_pattern": "AQUA_MODIS.*L2.SST4.|AQUA_MODIS.*L2.OC.|AQUA_MODIS.*L2.SST.",
        "processing_type": "MODIS_A",
        "processing_level": "L2",
        "num_days_back": "1",
        "granule_start_date": "dummy",
        "granule_end_date": "dummy",
        "naming_pattern_indicator": "GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE",
    }
    event_handler(event, None)