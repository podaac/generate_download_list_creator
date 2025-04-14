variable "app_name" {
  type        = string
  description = "Application name"
  default     = "generate"
}

variable "app_version" {
  type        = string
  description = "The application version number"
  default     = "0.1.3"
}

variable "aqua_processing_type" {
  type        = string
  description = "Generate workflow dataset to execute on"
  default     = "MODIS_A"
}

variable "aqua_search_filter" {
  type        = string
  description = "Search filter expression to query OBPG"
  default     = "A*202*.nc"
}

variable "aqua_search_pattern" {
  type        = string
  description = "Search pattern expression to search OBPG with"
  default     = "AQUA_MODIS.*L2.SST4.|AQUA_MODIS.*L2.OC.|AQUA_MODIS.*L2.SST."
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy to"
  default     = "us-west-2"
}

variable "creation_date" {
  type        = string
  description = "Indicate whether OBPG query should use creation date"
  default     = "1"
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type        = string
  description = "The environment in which to deploy to"
}

variable "granule_end_date" {
  type        = string
  description = "The end date of a temporal range to search"
  default     = "dummy"
}

variable "granule_start_date" {
  type        = string
  description = "The start date of a temporal range to search"
  default     = "dummy"
}

variable "naming_pattern_indicator" {
  type        = string
  description = "Indicates what version of the naming pattern to use"
  default     = "GHRSST_OBPG_USE_2019_NAMING_PATTERN_TRUE"
}

variable "num_days_back" {
  type        = string
  description = "The number of days back to search for"
  default     = "1"
}

variable "prefix" {
  type        = string
  description = "Prefix to add to all AWS resources as a unique identifier"
}

variable "processing_level" {
  type        = string
  description = "Data processing level"
  default     = "L2"
}

variable "terra_processing_type" {
  type        = string
  description = "Generate workflow dataset to execute on"
  default     = "MODIS_T"
}

variable "terra_search_filter" {
  type        = string
  description = "Search filter expression to query OBPG"
  default     = "T*202*.nc"
}

variable "terra_search_pattern" {
  type        = string
  description = "Search pattern expression to search OBPG with"
  default     = "TERRA_MODIS.*L2.SST4.|TERRA_MODIS.*L2.OC.|TERRA_MODIS.*L2.SST."
}

variable "viirs_processing_type" {
  type        = string
  description = "Generate workflow dataset to execute on"
  default     = "VIIRS"
}

variable "viirs_search_filter" {
  type        = string
  description = "Search filter expression to query OBPG"
  default     = "SNPP_VIIRS*202*"
}

variable "viirs_search_pattern" {
  type        = string
  description = "Search pattern expression to search OBPG with"
  default     = "SNPP_VIIRS.*SST.|SNPP_VIIRS.*SST3."
}

variable "jpss1_processing_type" {
  type        = string
  description = "Generate workflow dataset to execute on"
  default     = "JPSS1"
}

variable "jpss1_search_filter" {
  type        = string
  description = "Search filter expression to query OBPG"
  default     = "JPSS1_VIIRS*L2*SST*.nc"
}

variable "jpss1_search_pattern" {
  type        = string
  description = "Search pattern expression to search OBPG with"
  default     = "JPSS1_VIIRS.*L2.SST.|JPSS1_VIIRS.*L2.SST3."
}