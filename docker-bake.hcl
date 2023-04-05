# Docker Buildx Bake build definition file
# Reference: https://github.com/docker/buildx/blob/master/docs/reference/buildx_bake.md

variable "REGISTRY_USER" {
    default = "frappe"
}

variable "FRAPPE_VERSION" {
    default = "version-14"
}

variable "ERPNEXT_VERSION" {
    default = "version-14"
}

variable "FRAPPE_REPO" {
    default = "https://github.com/frappe/frappe"
}

variable "ERPNEXT_REPO" {
    default = "https://github.com/frappe/erpnext"
}

variable "BENCH_REPO" {
    default = "https://github.com/frappe/bench"
}

variable "BUILD_TARGET" {
    default = "erpnext"
}

variable "CUSTOM_VERSION" {
    default = "latest-test"
}

variable "APPS_JSON_BASE64" {
    default = "WwogIHsKICAgICJ1cmwiOiAiaHR0cHM6Ly9naXRodWIuY29tL2ZyYXBwZS9wYXltZW50cyIsCiAgICAiYnJhbmNoIjogImRldmVsb3AiCiAgfSwKICB7CiAgICAidXJsIjogImh0dHBzOi8vZ2l0aHViLmNvbS9mcmFwcGUvZXJwbmV4dCIsCiAgICAiYnJhbmNoIjogInZlcnNpb24tMTQiCiAgfQpdCg=="
}

# Bench image

target "bench" {
    args = {
        GIT_REPO = "${BENCH_REPO}"
    }
    context = "images/bench"
    target = "bench"
    tags = ["frappe/bench:latest"]
}

target "bench-test" {
    inherits = ["bench"]
    target = "bench-test"
}

# Main images
# Base for all other targets

group "default" {
    targets = ["${BUILD_TARGET}"]
}

function "tag" {
    params = [repo, version]
    result = [
      # If `version` param is develop (development build) then use tag `latest`
      "${version}" == "develop" ? "${REGISTRY_USER}/${repo}:latest" : "${REGISTRY_USER}/${repo}:${version}",
      # Make short tag for major version if possible. For example, from v13.16.0 make v13.
      can(regex("(v[0-9]+)[.]", "${version}")) ? "${REGISTRY_USER}/${repo}:${regex("(v[0-9]+)[.]", "${version}")[0]}" : "",
    ]
}

target "default-args" {
    args = {
        FRAPPE_PATH = "${FRAPPE_REPO}"
        ERPNEXT_PATH = "${ERPNEXT_REPO}"
        BENCH_REPO = "${BENCH_REPO}"
        FRAPPE_BRANCH = "${FRAPPE_VERSION}"
        ERPNEXT_BRANCH = "${ERPNEXT_VERSION}"
        PYTHON_VERSION = can(regex("v13", "${ERPNEXT_VERSION}")) ? "3.9.9" : "3.10.5"
        NODE_VERSION = can(regex("v13", "${FRAPPE_VERSION}")) ? "14.19.3" : "16.18.0"
    }
}

target "erpnext" {
    inherits = ["default-args"]
    context = "."
    dockerfile = "images/production/Containerfile"
    target = "erpnext"
    tags = tag("erpnext", "${ERPNEXT_VERSION}")
}


target "custom" {
    args = {
        APPS_JSON_BASE64="${APPS_JSON_BASE64}"
    }
    inherits = ["default-args"]    
    context = "."
    dockerfile = "images/custom/Containerfile"
    target = "builder"
    tags = ["hieutrluu/frappe_custom:${CUSTOM_VERSION}"]
}
