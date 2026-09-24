#!/bin/sh
#
# Download a pinned version of the crossplane CLI and verify its sha256 checksum.
#
# Adapted from the upstream install script at https://cli.crossplane.io/install.sh
# (retrieved 2026-09-24). Changes from upstream:
#   - requires a pinned XP_VERSION and an explicit output path
#   - verifies the binary against the published .sha256 file
#   - installs atomically so a failed download never leaves a binary behind
#   - drops Windows and compressed bundle support
#
# Usage: XP_VERSION=v1.20.13 install.sh <output-path>

set -eu

XP_CHANNEL=${XP_CHANNEL:-stable}
XP_VERSION=${XP_VERSION:-}

if [ "$#" -ne 1 ]; then
	echo "usage: XP_VERSION=<version> $0 <output-path>" >&2
	exit 1
fi
dest=$1

if [ -z "${XP_VERSION}" ] || [ "${XP_VERSION}" = "current" ]; then
	echo "XP_VERSION must be set to a pinned version (e.g. v1.20.13)." >&2
	exit 1
fi

# v2.3.0 was the first release from the crossplane/cli repository, whose
# artifacts go to the cli.crossplane.io bucket and uses the binary name
# "crossplane". Use the old releases.crossplane.io hostname and "crank" binary
# for older releases.
url_host="cli.crossplane.io"
bin="crossplane"

_ver=$(echo "${XP_VERSION}" | sed 's/^v//' | sed 's/-.*//')
_major=$(echo "${_ver}" | cut -d. -f1)
_minor=$(echo "${_ver}" | cut -d. -f2)
case "${_major}${_minor}" in
'' | *[!0-9]*)
	echo "Unable to parse XP_VERSION \"${XP_VERSION}\"." >&2
	exit 1
	;;
esac
if [ "${_major}" -lt 2 ] || { [ "${_major}" -eq 2 ] && [ "${_minor}" -lt 3 ]; }; then
	url_host="releases.crossplane.io"
	bin="crank"
fi

unsupported_arch() {
	echo "Crossplane does not support $1 / $2 at this time." >&2
	exit 1
}

os=$(uname -s)
arch=$(uname -m)
case $os in
Darwin)
	case $arch in
	x86_64 | amd64) os_arch=darwin_amd64 ;;
	arm64) os_arch=darwin_arm64 ;;
	*) unsupported_arch "$os" "$arch" ;;
	esac
	;;
Linux)
	case $arch in
	x86_64 | amd64) os_arch=linux_amd64 ;;
	arm64 | aarch64) os_arch=linux_arm64 ;;
	*) unsupported_arch "$os" "$arch" ;;
	esac
	;;
*)
	unsupported_arch "$os" "$arch"
	;;
esac

if command -v sha256sum >/dev/null 2>&1; then
	sha256() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
	sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
	echo "Neither sha256sum nor shasum is available to verify the download." >&2
	exit 1
fi

url="https://${url_host}/${XP_CHANNEL}/${XP_VERSION}/bin/${os_arch}/${bin}"

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

if ! curl -fsSL "${url}" -o "${tmp}/${bin}"; then
	echo "Failed to download ${url}. Please make sure version ${XP_VERSION} exists on channel ${XP_CHANNEL}." >&2
	exit 1
fi
if ! curl -fsSL "${url}.sha256" -o "${tmp}/${bin}.sha256"; then
	echo "Failed to download checksum ${url}.sha256." >&2
	exit 1
fi

expected=$(cut -d' ' -f1 <"${tmp}/${bin}.sha256" | tr -d '[:space:]')
actual=$(sha256 "${tmp}/${bin}")
if [ -z "${expected}" ] || [ "${expected}" != "${actual}" ]; then
	echo "Checksum mismatch for ${url}: expected \"${expected}\", got \"${actual}\"." >&2
	exit 1
fi

chmod +x "${tmp}/${bin}"
mkdir -p "$(dirname "${dest}")"
# Stage next to the destination so the final mv is an atomic rename.
mv "${tmp}/${bin}" "${dest}.tmp"
mv "${dest}.tmp" "${dest}"

echo "Installed crossplane CLI ${XP_VERSION} (${os_arch}) to ${dest}, sha256 ${actual}"
