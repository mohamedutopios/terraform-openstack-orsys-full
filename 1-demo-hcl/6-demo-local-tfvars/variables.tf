variable "env" {
  type    = string
  default = "dev"
}

variable "region" {
  type = string
}

variable "instances" {
  type    = list(string)
  default = ["web1", "web2", "web3"]
}

variable "tags" {
  type = map(string)
}