# download list creator

The downloade list creators searches the OBPG site and creates a list of files to download based on the arguments passed to the Docker container.

## pre-requisites to building

None.

## build command

`docker build --tag download_list_creator:0.1 . `

## execute command

Arguemnts:
1.	search_pattern
2.	output_directory
3.	processing_type
4.	processing_level
5.	state_file_name
6.	num_days_back
7.  granule_start_date
8.  granule_end_date
9.  naming_pattern_indicator

MODIS A: 
`docker run --rm --name dlc -v /dlc/data:/data download_list_creator:0.1 'AQUA_MODIS.*L2.SST4.|AQUA_MODIS.*L2.OC.|AQUA_MODIS.*L2.SST.' /data/output MODIS_A L2 /data/state_file/modis_a_state.txt 1 'dummy' 'dummy' GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE`

MODIS T: 
`docker run --rm --name dlc -v /dlc/data:/data download_list_creator:0.1 'TERRA_MODIS.*L2.SST4.|TERRA_MODIS.*L2.OC.|TERRA_MODIS.*L2.SST.' /data/output MODIS_T L2 /data/state_file/modis_t_state.txt 1 'dummy' 'dummy' GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE`

VIIRS: 
`docker run --rm --name dlc -v /dlc/data:/data download_list_creator:0.1 'SNPP_VIIRS.*SST.|SNPP_VIIRS.*SST3.' /data/output VIIRS L2 /data/state_file/viirs_state.txt 1 'dummy' 'dummy' GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE`

**NOTES**
- In order for the commands to execute the `/dlc/` directories will need to point to actual directories on the system.

## aws infrastructure

The download list creators includes the following AWS services:
- AWS Lambda function.
- AWS S3 bucket to hold output text files.
- AWS SQS queue to allow the publication of the list of text files.

## terraform 

Deploys AWS infrastructure and stores state in an S3 backend using a DynamoDB table for locking.

To deploy:
1. Edit `terraform.tfvars` for environment to deploy to.
2. Edit `terraform_conf/backed-{prefix}.conf` for environment deploy.
3. Initialize terraform: `terraform init -backend-config=terraform_conf/backend-{prefix}.conf`
4. Plan terraform modifications: `terraform plan -out=tfplan`
5. Apply terraform modifications: `terraform apply tfplan`

`{prefix}` is the account or environment name.