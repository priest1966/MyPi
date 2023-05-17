#!/usr/bin/env bash
echo "[i] Updating Pi-hole"
pihole -up

echo "[i] Updating lists"
if [ ! -f /etc/pihole/whitelist.txt ] ; then
sudo touch /etc/pihole/whitelist.txt
fi
sudo sort -u -o /etc/pihole/whitelist.txt /etc/pihole/whitelist.txt
if [ ! -f /etc/pihole/blacklist.txt ] ; then
sudo touch /etc/pihole/blacklist.txt
fi
sudo sort -u -o /etc/pihole/blacklist.txt /etc/pihole/blacklist.txt
if [ ! -f /etc/pihole/personal-adlists.list ] ; then
sudo touch /etc/pihole/personal-adlists.list
fi
if [ ! -f /etc/dnsmasq.d/wildcards.conf ] ; then
sudo touch /etc/dnsmasq.d/wildcards.conf
fi
cat /etc/pihole/personal-adlists.list <(wget -qO - https://v.firebog.net/hosts/lists.php?type=all) | grep -v '^$\|^\s*\#' | sudo sort -u -o /etc/pihole/adlists.list

echo "[i] Updating regex"
cat /etc/pihole/regex.list <(wget -qO - https://raw.githubusercontent.com/mmotti/pihole-regex/master/regex.list) | sudo sort -u -o /etc/pihole/regex.list
echo "[i] $(wc -l < /etc/pihole/regex.list) regex entries"

echo "[i] Updating gravity"
pihole -g >/dev/null
gravity=$(cat /etc/pihole/gravity.list | sed -E 's/^(\.|\-| )//g' | sed -E 's/<br>/\n/g' | grep -v "(\|)\|{\|}\|<\|>\|,\|\"\|'\|?\|\!\|§\|±\|€\|@\|#\|\^\|&\|*\|=\|+\|\`\|~\|\\\||" | sed -E 's/;(.*)//g' | sudo sort -u)
echo "[i] $(wc -l <<< "$gravity") gravity entries"

echo "[i] Removing entries covered by regex"
count_gravity=$(wc -l <<< "$gravity")
gravity=$(grep -vEf <(echo "$(grep '^[^#]' /etc/pihole/regex.list)") <<< "$gravity")
if [ -n "$gravity" ]; then
echo "[i] $(wc -l <<< "$gravity") entries remaining, $(($count_gravity - $(wc -l <<< "$gravity"))) unnecessary entries"
else
echo "[i] No unnecessary entries were found"
fi

echo "[i] Converting multiple entries to wildcards and fetching from sources"
auto_wildcards=$(echo "$gravity" | awk -F'.' 'BEGIN{i=0}index($0,prev FS)!=1{if(i>=20){print prev;}prev=$0;i=0;next}{++i}' | sort -u)
echo "[i] $(wc -l <<< "$auto_wildcards") wildcards created"
sourced_wildcards=$(curl -s https://raw.githubusercontent.com/justdomains/blocklists/master/lists/{adguarddns,easylist,easyprivacy}-justdomains.txt | sort -u | comm -23 - <(cat /etc/pihole/whitelist.txt)| awk -F'.' 'index($0,prev FS)!=1{ print; prev=$0 }' | sort -u)
echo "[i] $(wc -l <<< "$sourced_wildcards") wildcards fetched"
new_wildcards=$(echo "$auto_wildcards"$'\n'"$sourced_wildcards" | grep .)

existing_wildcards=$(find /etc/dnsmasq.d -type f -name "*.conf" -print0 | xargs -r0 grep -hE 'address=\/.+\/(([0-9]\.){3}[0-9]|::)?' | cut -d'/' -f2 | sort -u)
if [ -n "$existing_wildcards" ]; then
echo "[i] $(wc -l <<< "$existing_wildcards") wildcards already in existence"
echo "[i] Removing unnecessary wildcards"
count_wildcards=$(wc -l <<< "$new_wildcards")
new_wildcards=$(grep -vFf <(echo "$existing_wildcards") <<< "$new_wildcards" | sort -u)
echo "[i] $(wc -l <<< "$new_wildcards") new wildcards remaining, $(($count_wildcards - $(wc -l <<< "$new_wildcards"))) wildcards unnecessary"
else
echo "[i] No pre-existing wildcards, not removing any new wildcards"
fi
wildcards=$(echo "$(cat /etc/dnsmasq.d/wildcards.conf | grep -hE 'address=\/.+\/(([0-9]\.){3}[0-9]|::)?' | cut -d'/' -f2 | sort -u)"$'\n'"$new_wildcards" | grep .)
echo "[i] $(wc -l <<< "$wildcards") total wildcards"

echo "[i] Removing wildcards covered by regex"
count_pre_regex=$(wc -l <<< "$wildcards")
wildcards=$(grep -vEf <(echo "$(grep '^[^#]' /etc/pihole/regex.list)") <<< "$wildcards" | sort -u)
echo "$wildcards" | perl -lne 'print "address=/$_/0.0.0.0\naddress=/$_/::"' | sudo tee /etc/dnsmasq.d/wildcards.conf >/dev/null
if [ -n "$wildcards" ]; then
echo "[i] $(wc -l <<< "$wildcards") wildcards remaining, $((($count_pre_regex)-$(wc -l <<< "$wildcards"))) wildcards removed"
else
echo "[i] no wildcards remaining after regex removals"
fi

echo "[i] Removing wildcard matches from gravity"
all_wildcards=$(echo "$existing_wildcards"$'\n'"$new_wildcards" | grep .)
all_wildcards=$(find /etc/dnsmasq.d -type f -name "*.conf" -print0 | xargs -r0 grep -hE 'address=\/.+\/(([0-9]\.){3}[0-9]|::)?' | cut -d'/' -f2 | sort -u)
echo "[i] $(wc -l <<< "$all_wildcards") total wildcards in existence in all locations"
count_gravity=$(wc -l <<< "$gravity")
if [ -n "$all_wildcards" ] || [ -n "$gravity" ]; then
gravity=$(grep -vFf <(echo "$(perl -lne 'print ".$_\$\n^$_\$"' <<< "$all_wildcards")") <<< "$(perl -lne 'print "^$_\$"' <<< "$gravity")" | sed 's/[\^$]//g')
fi
echo "[i] $(($count_gravity - $(wc -l <<< "$gravity"))) unnecessary domains found in gravity"
echo "$gravity" | sudo tee /etc/pihole/gravity.list >/dev/null
echo "[i] $(wc -l <<< /etc/pihole/gravity.list) entries in gravity"

echo "[i] Restarting Pi-hole"
sudo killall -SIGHUP pihole-FTL

echo "[i] Updating Unbound"
sudo wget -qO - https://www.internic.net/domain/named.root >/var/lib/unbound/root.hints

echo "[i] Commenting out original cron for updating gravity"
sudo sed -e '/pihole updateGravity/ s/^#*/#/' -i /etc/cron.d/pihole

echo "[i] Updating OS"
sudo bash -c 'for i in update {,dist-}upgrade auto{remove,clean}; do apt $i -y; done'


exit 0
