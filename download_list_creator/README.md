# download list creator

The downloade list creators searches the OBPG site and creates a list of files to download based on the arguments passed to the Docker container.

## pre-requisites to building

None.

## build command

`docker build --tag download_list_creator:0.1 . `

## execute command

MODIS A: 
`docker run --name gen-dllc -v /download_list_creator/logs:/data/logs -v /download_list_creator/output:/data/output -v /download_list_creator/state_file:/data/state_file list-creator:0.1 'L2.SST4.|L2.SST.|L2.OC.|L2_LAC_OC.' /data/output MODIS_A L2 /data/state_file/modis_aqua_level2_03_22_state.txt 1 '2022-03-22' '2022-03-23'`

MODIS T: 
`docker run --name gen-dllc -v /download_list_creator/logs:/data/logs -v /download_list_creator/output:/data/output -v /download_list_creator/state_file:/data/state_file list-creator:0.1 'L2.SST4.|L2.SST.|L2.OC.|L2_LAC_OC.' /data/output MODIS_T L2 /data/state_file/modis_terra_level2_03_22_state.txt 1 '2022-03-22' '2022-03-23'`

VIIRS: 
`docker run --name gen-dllc -v /download_list_creator/logs:/data/logs -v /download_list_creator/output:/data/output -v /download_list_creator/state_file:/data/state_file list-creator:0.1 'SST.|SST3.' /data/output VIIRS L2 /data/state_file/viirs_level2_03_22_state.txt 1 '2022-03-22' '2022-03-23'`

Please note that in order for the commands to execute the `/download_list_creator/` directories will need to point to actual directories on the system.