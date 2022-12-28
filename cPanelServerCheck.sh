#! /opt/alt/python27/bin/python2.7

import commands
import subprocess

TotalUsageOnServer = 0
TotalLimitOnServer = 0
Total_Shared_Usage = 0
Total_Reseller_Usage = 0

# Open file for reading
fileObject = open("/etc/trueuserowners", "r")

# Reseller dict
resellers = {}
shared_accounts = {}
reseller_accounts = {}
root_accounts = {}

# Convert reseller & child info into the reseller dict
for line in fileObject:
    cpanel_owner = (line.split()[0])[:-1]
    reseller_owner = (line.split()[1])
    cpanel_array = []
    if reseller_owner in resellers:
        resellers[reseller_owner].append(cpanel_owner)
    else:
        cpanel_array.append(cpanel_owner)
        resellers[reseller_owner] = cpanel_array


# Get disk usage
def get_total_usage(owner):
    global TotalUsageOnServer
    global TotalLimitOnServer
    total_disk_usage = 0
    total_limit = 0
    for x in resellers[owner]:
        mb_value = str(
            commands.getstatusoutput("uapi --user=" + str(x) + " Quota get_quota_info|grep -E 'megabytes_used: '"))
        usage = (((mb_value.split()[3]).replace('"', '')).replace("'", "")).strip(")")
        total_disk_usage += float(usage)
        limit_value = str(commands.getstatusoutput("uapi --user=" + str(x) + " Quota get_quota_info | grep -w 'megabyte_limit:'"))
        limit_usage = (((limit_value.split()[3]).replace('"', '')).replace("'", "")).strip(")")
        total_limit += float(limit_usage)

    TotalUsageOnServer += float(total_disk_usage)
    TotalLimitOnServer += float(total_limit)

def get_disk_usage(username):
    mb_value = str(
        commands.getstatusoutput("uapi --user=" + str(username) + " Quota get_quota_info|grep -E 'megabytes_used: '"))
    usage = (((mb_value.split()[3]).replace('"', '')).replace("'", "")).strip(")")
    return usage


def check_if_reseller(owner, child, index):
    if owner == "root":
        for y in range(index+1):
            shared_accounts[(child[y])] = {}
            shared_accounts[(child[y])]['Disk_Usage'] = get_disk_usage((child[y]))
    elif len(child) < 2:
        shared_accounts[owner] = {}
        shared_accounts[owner]['Disk_Usage'] = get_disk_usage(owner)
    else:
        reseller_accounts[owner] = {}
        for x in range(index+1):
            reseller_accounts[owner][child[x]] = get_disk_usage(child[x])


# For loop to run through resellers to get disk usage
for key in resellers:
    check_if_reseller(key, resellers[key], len(resellers[key])-1)
    get_total_usage(key)

for i in shared_accounts:
    Total_Shared_Usage += float((shared_accounts[i].values())[0])

for i in reseller_accounts:
    for v in range (len(reseller_accounts[i].values())):
        Total_Reseller_Usage += float((reseller_accounts[i].values())[v])

hostname_cmd = 'cat /proc/sys/kernel/hostname'
hostname_result = subprocess.check_output(hostname_cmd, shell=True)

print("------")
print("Hostname: " + str(hostname_result.strip()))
print("Total disk usage on server: " + str(TotalUsageOnServer) + "MB")
print("")
print("Number of resellers on the server: " + str(len(reseller_accounts.keys())))
print("Total usage of resellers on the server: " + str(Total_Reseller_Usage) + "MB")
print(reseller_accounts)
print("")
print("Number of shared cPanels on the server: " + str(sum(len(v) for v in shared_accounts.values())))
print("Total usage of shared cPanels on the server: " + str(Total_Shared_Usage) + "MB")
print(shared_accounts)
print("------")
