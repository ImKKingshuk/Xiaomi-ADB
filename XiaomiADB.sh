#!/bin/bash


LOG_FILE="/tmp/xiaomiadb.log"

print_banner() {
    local banner=(
        "******************************************"
        "*                Xiaomi-ADB              *"
        "*    Xiaomi Device Customizer with ADB   *"
        "*                  v1.0.1                *"
        "*      ----------------------------      *"
        "*                        by @ImKKingshuk *"
        "* Github- https://github.com/ImKKingshuk *"
        "******************************************"
    )
    local width=$(tput cols)
    for line in "${banner[@]}"; do
        printf "%*s\n" $(((${#line} + width) / 2)) "$line"
    done
    echo
}


log_info() {
    echo "[INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
        log_info "Backup created for $file"
    fi
}

modify_xml_property() {
    local xml_file="$1"
    local property="$2"
    local value="$3"
    local line_no

    line_no=$(grep -n "$property" "$xml_file" | awk -F: '{print $1}')
    if [ "$line_no" ]; then
        log_info "Found $property at line $line_no"
        sed -i "/$property/s/false/$value/" "$xml_file"
    else
        log_info "$property not found, inserting..."
        sed -i "3a \ \ \ \ <boolean name=\"$property\" value=\"$value\" />" "$xml_file"
    fi

    grep "$property" "$xml_file" | tee -a "$LOG_FILE"
}

restart_service() {
    local service_name="$1"
    pkill -9 "$service_name" && log_info "$service_name service restarted"
}


disable_ads() {
    local xml_file="/data/data/com.miui.securitycenter/shared_prefs/remote_provider_preferences.xml"
    log_info "Disabling ads in the Security App..."
    backup_file "$xml_file"
    modify_xml_property "$xml_file" "ads_enabled" "false"
}

enable_all_permissions() {
    log_info "Enabling all permissions for all apps..."
    pm grant com.miui.securitycenter android.permission.READ_LOGS
    pm grant com.miui.securitycenter android.permission.ACCESS_FINE_LOCATION
    pm grant com.miui.securitycenter android.permission.ACCESS_COARSE_LOCATION
    pm grant com.miui.securitycenter android.permission.READ_CONTACTS
    pm grant com.miui.securitycenter android.permission.WRITE_CONTACTS
    pm grant com.miui.securitycenter android.permission.CALL_PHONE
    pm grant com.miui.securitycenter android.permission.READ_PHONE_STATE
    pm grant com.miui.securitycenter android.permission.READ_CALL_LOG
    pm grant com.miui.securitycenter android.permission.WRITE_CALL_LOG
    pm grant com.miui.securitycenter android.permission.SEND_SMS
    pm grant com.miui.securitycenter android.permission.RECEIVE_SMS
    log_info "All permissions enabled for com.miui.securitycenter"
}

bypass_battery_optimization() {
    log_info "Bypassing battery optimization for selected apps..."
    powercfg=$(dumpsys deviceidle | grep "whitelist=" | sed 's/whitelist=//')
    app_list="com.miui.securitycenter com.android.settings"
    for app in $app_list; do
        if [[ $powercfg != *"$app"* ]]; then
            dumpsys deviceidle whitelist +$app
            log_info "Bypassed battery optimization for $app"
        else
            log_info "$app is already bypassing battery optimization"
        fi
    done
}

unlock_dev_options() {
    log_info "Unlocking hidden developer options..."
    settings put global development_settings_enabled 1
    settings put global adb_enabled 1
    settings put global verity_mode 0
    log_info "Developer options unlocked"
}

disable_miui_optimization() {
    log_info "Disabling MIUI/HyperOS optimization..."
    settings put global miui_optimization 0
    log_info "MIUI/HyperOS optimization disabled"
}

enable_third_party_themes() {
    log_info "Enabling third-party themes..."
    settings put secure theme_authorization 1
    log_info "Third-party themes enabled"
}


print_banner
check_root

echo "Select an option:"
echo "1. Enable USB debugging"
echo "2. Enable Fastboot"
echo "3. Enable Installation via USB"
echo "4. Disable install intercept"
echo "5. Disable Ads in Security App"
echo "6. Enable All Permissions for Security App"
echo "7. Bypass Battery Optimization for Selected Apps"
echo "8. Unlock Hidden Developer Options"
echo "9. Disable MIUI Optimization"
echo "10. Enable Third-Party Themes"
echo "11. Apply all modifications"
echo "12. Exit"

read -rp "Enter your choice: " choice

XML_FILE="/data/data/com.miui.securitycenter/shared_prefs/remote_provider_preferences.xml"

case $choice in
    1)
        log_info "Enabling USB debugging (Security settings)..."
        RESULT=$(getprop persist.security.adbinput)
        if [[ $RESULT != "1" ]]; then
            setprop persist.security.adbinput 1 && log_info "USB debugging (Security settings) enabled"
        else
            log_info "USB debugging (Security settings) is already enabled"
        fi
        ;;
    2)
        log_info "Enabling Fastboot..."
        RESULT=$(getprop persist.fastboot.enable)
        if [[ $RESULT != "1" ]]; then
            setprop persist.fastboot.enable 1 && log_info "Fastboot enabled"
        else
            log_info "Fastboot is already enabled"
        fi
        ;;
    3)
        log_info "Modifying $XML_FILE for USB installation..."
        backup_file "$XML_FILE"
        modify_xml_property "$XML_FILE" "security_adb_install_enable" "true"
        ;;
    4)
        log_info "Modifying $XML_FILE to disable install intercept..."
        backup_file "$XML_FILE"
        modify_xml_property "$XML_FILE" "permcenter_install_intercept_enabled" "false"
        ;;
    5)
        disable_ads
        ;;
    6)
        enable_all_permissions
        ;;
    7)
        bypass_battery_optimization
        ;;
    8)
        unlock_dev_options
        ;;
    9)
        disable_miui_optimization
        ;;
    10)
        enable_third_party_themes
        ;;
    11)
        log_info "Applying all modifications..."
        
        RESULT=$(getprop persist.security.adbinput)
        if [[ $RESULT != "1" ]]; then
            setprop persist.security.adbinput 1 && log_info "USB debugging (Security settings) enabled"
        fi
      
        RESULT=$(getprop persist.fastboot.enable)
        if [[ $RESULT != "1" ]]; then
            setprop persist.fastboot.enable 1 && log_info "Fastboot enabled"
        fi
       
        backup_file "$XML_FILE"
        modify_xml_property "$XML_FILE" "security_adb_install_enable" "true"
       
        modify_xml_property "$XML_FILE" "permcenter_install_intercept_enabled" "false"
        
        disable_ads
       
        enable_all_permissions
       
        bypass_battery_optimization
      
        unlock_dev_options
      
        disable_miui_optimization
     
        enable_third_party_themes
        restart_service "com.miui.securitycenter.remote"
        ;;
    12)
        log_info "Exiting..."
        exit 0
        ;;
    *)
        log_error "Invalid choice. Exiting..."
        exit 1
        ;;
esac

log_info "Done!"