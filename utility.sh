#!/bin/bash

get_response_code() {
    echo $(curl --write-out '%{http_code}' --silent --output /dev/null "$1");
}

is_container_running() {
    is_running=$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null);
    echo "${is_running:=false}";
}

open_url_when_available() {
    wait_until_url_available "$1";
    error_message="Unable to automatically open '$1', try opening it in a browser"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS system
        open ${2:+-a "$2"} "$1" || echo "$error_message"
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux system
        xdg-open "$1" || echo "$error_message"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows system (Cygwin, Git Bash, or WSL)
        start "" "$1" || echo "$error_message"
    else
        echo "Unsupported operating system"
    fi
}

wait_until_url_available() {
    while ! [[ "$(get_response_code $1)" =~ ^(200|301)$ ]]; do sleep 1; done;
    sleep 0.5;
}

apply_mediawiki_skin_settings() {
    cd "$mediawikiPath";
    grep -qx "^wfLoadSkin([\"']$wfLoadSkin[\"']); *$" LocalSettings.php || echo "wfLoadSkin(\"$wfLoadSkin\");" >> LocalSettings.php;
    sed -i -E "s/\\\$wgDefaultSkin.*;[[:blank:]]*$/\\\$wgDefaultSkin = \"$wgDefaultSkin\";/g" LocalSettings.php;
}

apply_mediawiki_skin() {
    cd "$mediawikiPath";
    rm -rf "skins/$skinSubdirectory";
    git clone --branch "$skinBranch" "$skinRepoURL" "./skins/$skinSubdirectory" --depth=1;
    sleep 1;
    apply_mediawiki_skin_settings;
}

apply_mediawiki_extension_settings() {
    cd "$mediawikiPath";
    grep -qx "^[[:blank:]]*wfLoadExtension[[:blank:]]*([[:blank:]]*[\"']$wfLoadExtension[\"'][[:blank:]]*)[[:blank:]]*;[[:blank:]]*$" LocalSettings.php || echo "wfLoadExtension(\"$wfLoadExtension\");" >> LocalSettings.php;
}

apply_mediawiki_extension() {
    cd "$mediawikiPath";
    rm -rf "extensions/$extensionSubdirectory";
    git clone --branch "$extensionBranch" "$extensionRepoURL" "./extensions/$extensionSubdirectory" --depth=1;
    sleep 1;
    apply_mediawiki_extension_settings;
}

"$@"
