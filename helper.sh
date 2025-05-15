#!/bin/sh

set -e
clear

HELPER_SCRIPT_FOLDER="$(dirname "$(readlink -f "$0")")"
for script in "${HELPER_SCRIPT_FOLDER}/scripts/"*.sh; do . "${script}"; done
for script in "${HELPER_SCRIPT_FOLDER}/scripts/menu/"*.sh; do . "${script}"; done
for script in "${HELPER_SCRIPT_FOLDER}/scripts/menu/K1/"*.sh; do . "${script}"; done
for script in "${HELPER_SCRIPT_FOLDER}/scripts/menu/3V3/"*.sh; do . "${script}"; done
for script in "${HELPER_SCRIPT_FOLDER}/scripts/menu/3KE/"*.sh; do . "${script}"; done
for script in "${HELPER_SCRIPT_FOLDER}/scripts/menu/10SE/"*.sh; do . "${script}"; done

function update_helper_script() {
  echo -e "${white}"
  echo -e "Info: Updating Creality Helper Script..."
  cd "${HELPER_SCRIPT_FOLDER}"
  git reset --hard && git pull
  # Check if the latest commit is signed
  # If not, roll back the changes and exit with an error message
  if ! git log -1 --pretty=format:'%G?' | grep -q "G"; then
    echo -e "${red}Error: No valid signature found in the latest commit. Rolling back changes.${white}"
    git reset --hard HEAD@{1}
    exit 1
  fi
  ok_msg "Creality Helper Script has been updated!"
  echo -e "   ${green}Please restart script to load the new version.${white}"
  echo
  exit 0
}

function update_available() {
  [[ ! -d "${HELPER_SCRIPT_FOLDER}/.git" ]] && return
  local remote current
  cd "${HELPER_SCRIPT_FOLDER}"
  ! git branch -a | grep -q "\* main" && return
  git fetch -q > /dev/null 2>&1
  # Check if the latest fetched commit is signed (we don't accept an unsigned commit)
  if ! git log FETCH_HEAD -1 --pretty=format:'%G?' | grep -q "G"; then
    echo "unsigned"
    return
  fi
  remote=$(git rev-parse --short=8 FETCH_HEAD)
  current=$(git rev-parse --short=8 HEAD)
  if [[ ${remote} != "${current}" ]]; then
    echo "true"
  fi
}

function update_menu() {
  local update_available=$(update_available)
  if [[ "$update_available" == "true" ]]; then
    top_line
    title "A new script version is available!" "${green}"
    inner_line
    hr
    echo -e " │ ${cyan}It's recommended to keep script up to date. Updates usually    ${white}│"
    echo -e " │ ${cyan}contain bug fixes, important changes or new features.          ${white}│"
    echo -e " │ ${cyan}Please consider updating!                                      ${white}│"
    hr 
    echo -e " │ See changelog here: ${yellow}https://tinyurl.com/3sf3bzck               ${white}│"
    hr
    bottom_line
    local yn
    while true; do
      read -p " Do you want to update now? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
      case "${yn}" in
        Y|y)
          run "update_helper_script"
          if [ ! -x "$HELPER_SCRIPT_FOLDER"/helper.sh ]; then
            chmod +x "$HELPER_SCRIPT_FOLDER"/helper.sh >/dev/null 2>&1
          fi
          break;;
        N|n)
          break;;
        *)
          error_msg "Please select a correct choice!";;
      esac
    done
  elif [[ "$update_available" == "unsigned" ]]; then
    echo -e "${red}Error: No valid signature found in the latest fetched commit.${white}"
    echo "The update will not be applied."
    echo "Please check the repository for any issues."
    echo "If you are sure that the update is safe, you can manually update it."
  fi
}

if [ ! -L /usr/bin/helper ]; then
  ln -sf "$HELPER_SCRIPT_FOLDER"/helper.sh /usr/bin/helper > /dev/null 2>&1
fi
rm -rf /root/.cache
set_paths
set_permissions
update_menu
main_menu
