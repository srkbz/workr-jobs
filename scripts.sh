#!/usr/bin/env bash
set -euo pipefail
ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

function clone-git-repository {
    repo="$1"
    path="$2"
    if [ -d "${path}" ]; then
        log "Updating repository ${repo}"
        (cd "${path}" && git pull)
    else
        log "Cloning repository ${repo}"
        git clone "${repo}" "${path}"
    fi
    log-newline
}

function show-latest-github-artifacts {
    user="$1"
    repo="$2"
    download_links=$(curl -sq "https://api.github.com/repos/${user}/${repo}/releases/latest" | jq -r ".assets[].browser_download_url")
    log "Download links:"
    while read -r link; do
        printf "%s\n" "$link"
    done <<< "$download_links"
}

function package-tar {
    log "Packaging into tar ${2}"
    path="$(pwd)/$1"
    target="$(pwd)/$2"
    (
        cd "${path}"
        tar --create --gzip --file "${target}" *
    )
}

function package-deb {(
    log "Packaging into deb ${2}"
    path="$(pwd)/$1"
    target="$(pwd)/$2"
    package="$3"
    version="$4"
    web="$5"

    rm -rf "./deb-pkg"
    mkdir -p "./deb-pkg/workr/usr/bin"
    cp -r "${path}"/* "./deb-pkg/workr/usr/bin"
    mkdir -p "./deb-pkg/workr/DEBIAN"
    (
        export PACKAGE="${package}"
        export VERSION="${version}"
        export WEB="${web}"
        envsubst < "${ROOT}/assets/deb-control" > "./deb-pkg/workr/DEBIAN/control"
    )
    (cd "./deb-pkg" && dpkg-deb --build workr)
    mv "./deb-pkg/workr.deb" "${target}"
)}

function create-release {
    user="$1"
    repo="$2"
    version="$3"
    name="$4"
    commit="$5"
    description="$6"
    log "Creating release ${name} ${version} (${user}/${repo}#${commit})"
    github-release release \
        --user "${user}" \
        --repo "${repo}" \
        --tag "v${version}" \
        --name "${name} ${version}" \
        --description "${description}" \
        --target "${commit}"
}

function upload-release-file {
    user="$1"
    repo="$2"
    version="$3"
    file="$(pwd)/$4"
    file_name="$(basename "${file}")"
    log "Uploading ${file_name}"
    github-release upload \
        --user "${user}" \
        --repo "${repo}" \
        --tag "v${version}" \
        --name "${file_name}" \
        --file "${file}"
}

function log { printf "## %s\n" "$1"; }
function log-newline { printf "\n"; }
