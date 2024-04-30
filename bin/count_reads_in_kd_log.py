import sys
from os import path

# Function to parse a file
def get_read_info(kd_log_file):
    read_info = []
    metaID = path.basename(kd_log_file).replace("_1_kneaddata.log", "")
    with open(kd_log_file, 'r') as kd_log:
        for line in kd_log:
            if "READ COUNT" in line:
                split_read = line.split("READ COUNT: ")
                split_read2 = split_read[1].split(":")
                read_count_line = metaID + "\t" + split_read2[0].strip() + "\t" + split_read2[-1].strip() + "\n"
                read_info.append(read_count_line)

    return read_info

in_log_list = sys.argv[1:-1]
read_count_report_out = sys.argv[-1]

with open(read_count_report_out, 'w') as fout:
    for logfile in in_log_list:
        read_info = get_read_info(logfile)
        for line in read_info:
            fout.write(f"{line}")