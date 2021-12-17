# Docker Buildx Bake build definition file
# Reference: https://github.com/docker/buildx/blob/master/docs/reference/buildx_bake.md

variable "USERNAME" {
    default = "frappe"
}

variable "FRAPPE_VERSION" {
    default = "develop"
}

variable "ERPNEXT_VERSION" {
    default = "develop"
}

# Bench image

target "bench" {
    context = "build/bench"
    target = "bench"
    tags = ["frappe/bench:latest"]
}

target "bench-test" {
    inherits = ["bench"]
    target = "bench-test"
}

# Main images
# Base for all other targets

group "frappe" {
    targets = ["frappe-worker", "frappe-nginx", "frappe-socketio"]
}

group "erpnext" {
    targets = ["erpnext-worker", "erpnext-nginx"]
}

group "default" {
    targets = ["frappe", "erpnext"]
}

function "tag" {
    params = [repo, version]
    # If `version` parameter is develop (development build) then use tag `latest`
    result = ["${version}" == "develop" ? "${USERNAME}/${repo}:latest" : "${USERNAME}/${repo}:${version}"]
}

target "default-args" {
    args = {
        FRAPPE_VERSION = "${FRAPPE_VERSION}"
        ERPNEXT_VERSION = "${ERPNEXT_VERSION}"
        # If `ERPNEXT_VERSION` variable contains "v12" use Python 3.7. Else — 3.9.
        PYTHON_VERSION = can(regex("v12", "${ERPNEXT_VERSION}")) ? "3.7" : "3.9"
    }
}

target "frappe-worker" {
    inherits = ["default-args"]
    context = "build/worker"
    target = "frappe"
    tags = tag("frappe-worker", "${FRAPPE_VERSION}")
}

target "erpnext-worker" {
    inherits = ["default-args"]
    context = "build/worker"
    target = "erpnext"
    tags =  tag("erpnext-worker", "${ERPNEXT_VERSION}")
}

target "frappe-nginx" {
    inherits = ["default-args"]
    context = "build/nginx"
    target = "frappe"
    tags =  tag("frappe-nginx", "${FRAPPE_VERSION}")
}

target "erpnext-nginx" {
    inherits = ["default-args"]
    context = "build/nginx"
    target = "erpnext"
    tags =  tag("erpnext-nginx", "${ERPNEXT_VERSION}")
}

target "frappe-socketio" {
    inherits = ["default-args"]
    context = "build/socketio"
    tags =  tag("frappe-socketio", "${FRAPPE_VERSION}")
}
