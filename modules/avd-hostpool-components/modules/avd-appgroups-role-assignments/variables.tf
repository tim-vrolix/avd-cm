variable "appgroup_resource_id" {
  description = "Application group resource id."
  type        = string
}

variable "assignment_list" {
  description = "List of users/groups that need to be role assigned."
  type        = any
}