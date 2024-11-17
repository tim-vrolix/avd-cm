locals {
  var_file = "../Main-Parameters-dev.yml"
  var_file_content = fileexists(local.var_file) ? file(local.var_file) : "NoSettingsFileFound: true"
  var_config = yamldecode(local.var_file_content)
}