#!/usr/bin/python
# -*- coding: utf-8 -*-

"""Convert accidents from a text-form Mt. Lebanon police blotter into CSV data.
"""

import csv
import fileinput
import re
import sys

def main():
    csv_out = csv.writer(sys.stdout)
    csv_out.writerow('date time vehicles injuries tows location text'.split())
    accident_lines = get_accident_lines(fileinput.input())
    for line in accident_lines:
        csv_out.writerow(parse_accident_description(line))

def get_accident_lines(lines):
    in_accident_block = False
    for line in lines:
        if not in_accident_block:
            # Accident block starts with a header.
            if re.match('ACCIDENT', line):
                in_accident_block = True
        else:
            # Accident block ends with an empty line.
            if not re.search(r'\w', line):
                in_accident_block = False
                continue
            # Everything line within the block is an accident description.
            yield line

def parse_accident_description(line):
    """Parse a description of an accident.

    Example lines:
    Robb Hollow Road – Pedestrian stuck by vehicle in parking lot. 04/23/13 1425
    Sunset Drive – 2 vehicles, 1 injury, 2 tows. 04/23/13 1511
    Cochran Road – Hit & Run, vehicle struck at stop light. 04/25/13 0916
    """
    line = line.decode('utf8').replace(u'\u00a0', ' ').replace(u'\u2013', '-')
    match = re.match(ACCIDENT_DESCRIPTION_RE, line, re.U)
    if match:
        location, text, date, time = match.groups()
        vehicles = '1'
        injuries = tows = '0'
        # Vehicles.
        match = re.search(r'(\d+)\s+vehicle', text)
        def get_value(unit, default):
            match = re.search(r'(\d+)\s+' + unit, text)
            return match.group(1) if match else default
        vehicles = get_value('vehicle', '1')
        injuries = get_value('injur', '0')
        tows = get_value('tow', '0')
        time = '%s:%s' % (time[:2], time[2:])
        return date, time, vehicles, injuries, tows, location, text
    raise Exception('Bad parse: ' + line.encode('utf8'))

ACCIDENT_DESCRIPTION_RE = r'(.*?)\s+-\s+(.*?)\s+(\d\d/\d\d/\d\d)\s+(\d{4})'

if __name__ == '__main__':
    main()
