#!/bin/bash

update_rspamd() {
  # Get latest rspamd version and calculate sha256 hash of the tarball
  RSPAMD_VER=$(wget -q -O - 'https://api.github.com/repos/rspamd/rspamd/releases/latest' | jq -r ".tag_name")
  RSPAMD_SHA256_HASH=$(wget -q -O - "https://github.com/rspamd/rspamd/archive/$RSPAMD_VER.tar.gz" | sha256sum --zero | perl -lane 'print $F[0]')

  # Update Dockerfile
  perl -pi -e "s/RSPAMD_VER=\K.*/$RSPAMD_VER/" Dockerfile
  perl -pi -e "s/RSPAMD_SHA256_HASH=\K.*/\"$RSPAMD_SHA256_HASH\"/" Dockerfile
  # Update README
  perl -pi -e "s/^\* Rspamd \K(\d|\.)*/$RSPAMD_VER/" README.md
}

update_gucci() {
  local GUCCI_VER=$(wget -q -O - 'https://api.github.com/repos/noqcks/gucci/releases/latest' | jq -r ".tag_name")
  local GUCCI_SHA256_HASH=$(wget -q -O - "https://github.com/noqcks/gucci/releases/download/$GUCCI_VER/gucci-v$GUCCI_VER-linux-amd64" | sha256sum --zero | perl -lane 'print $F[0]')

  # Update Dockerfile
  perl -pi -e "s/GUCCI_VER=\K.*/$GUCCI_VER/" Dockerfile
  perl -pi -e "s/GUCCI_SHA256_HASH=\K.*/\"$GUCCI_SHA256_HASH\"/" Dockerfile
  # Update README
  perl -pi -e "s/^\* Gucci \K(\d|\.)*/$GUCCI_VER/" README.md
}

update_skarnet_dependency() {
  local DEPENDENCY_NAME_README="$1"
  # convert all characters to lowercase
  local DEPENDENCY_NAME="${DEPENDENCY_NAME_README:l}"
  local DEPENDENCY_VER=$(wget -q -O - "https://api.github.com/repos/skarnet/$DEPENDENCY_NAME/tags" | jq -r ".[0].name")
  # Remove v from the start
  local DEPENDENCY_VER=${DEPENDENCY_VER#v}
  local DEPENDENCY_SHA256_HASH=$(wget -q -O - "https://skarnet.org/software/$DEPENDENCY_NAME/$DEPENDENCY_NAME-$DEPENDENCY_VER.tar.gz" | sha256sum --zero | perl -lane 'print $F[0]')
  # Update Dockerfile
  perl -pi -e "s/${DEPENDENCY_NAME_README:u}_VER=\K.*/$DEPENDENCY_VER/" Dockerfile
  perl -pi -e "s/${DEPENDENCY_NAME_README:u}_SHA256_HASH=\K.*/\"$DEPENDENCY_SHA256_HASH\"/" Dockerfile
  # Update README
  perl -pi -e "s/^\* $DEPENDENCY_NAME_README \K(\d|\.)*/$DEPENDENCY_VER/" README.md
}

update_rspamd
update_gucci
update_skarnet_dependency Skalibs
update_skarnet_dependency Execline
update_skarnet_dependency s6
