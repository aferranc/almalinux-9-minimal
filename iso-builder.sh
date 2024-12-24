#!/bin/bash

# Set default variables
CREATE_TAG="${CREATE_TAG:-yes}"
PRODUCT="${PRODUCT:-LMS}"

# Si la variable CREATE_TAG está declarada con 'yes', se verificará si de la rama 'main'/'master' ya existe un tag para el mismo commit
# Si no existe un tag referenciado a dicho commit, se crea un tag nuevo
# if [[ "${CREATE_TAG^^}" == "YES" ]]; then
#     echo "CI_COMMIT_SHA: ${CI_COMMIT_SHA}"
#     TAG_CI_BUILD_REF=$(git tag --contains "${CI_COMMIT_SHA}")

#     if git tag | sort -V | grep "${PRODUCT^^}" | grep "p"; then
#         TAG_NUM=$(git tag | sort -V | grep "${PRODUCT^^}" | grep "p" | tail -n 1 | tr -dc '0-9')
#         ((TAG_NUM++))
#         TAG_NEW=${PRODUCT^^}_p${TAG_NUM}
#     else
#         TAG_NEW=${PRODUCT^^}_p1
#     fi

#     if [ -z "${TAG_CI_BUILD_REF}" ]; then
#         echo "Creating tag [${TAG_NEW}]..."
#         git tag -a "${TAG_NEW}" -m "version ${TAG_NEW} [skip ci]"
#         echo "Push tag ${TAG_NEW}"
#         git push --push-option='ci.skip' --tags "https://${CI_USER}:${CI_TOKEN}@${CI_REPOSITORY_URL#*@}" "HEAD:${CI_COMMIT_REF_NAME}"
#         TAG_CURRENT=${TAG_NEW}
#     else
#         echo "The CI_COMMIT_SHA has a tag associated: ${TAG_CI_BUILD_REF}"
#         echo "A new tag is not created"
#         TAG_CURRENT=${TAG_CI_BUILD_REF}
#     fi
# fi

# Clean environment
echo "Clean environment ......"
./bootstrap.sh clean

# Enlace simbólico del fichero packages.txt
echo "Creating symlink ...."
ln -sfv packages_"${PRODUCT,,}".txt packages.txt

# Se genera ISO asociada con el tag
echo "Launch iso_creator.sh ......"
./bootstrap.sh run "${PRODUCT^^}" "${TAG_CURRENT}"

# # Se carga el nombre de la ISO generada
# source out.txt

# # Se sube ISO al repositorio
# echo "Uploading ISO [${ISO_NAME}] to ${NEXUS_HOST} [isos/devel/${PRODUCT^^}]"
# curl --user "$NEXUS_USER:$NEXUS_PASS" --upload-file "${ISO_NAME}" https://"${NEXUS_HOST}"/repository/isos/devel/"${PRODUCT^^}"/"${ISO_NAME}"
