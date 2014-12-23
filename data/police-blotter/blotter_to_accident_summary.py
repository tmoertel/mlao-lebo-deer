#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Tom Moertel <tom@moertel.com>

"""Convert accident data from Mt. Lebanon police blotter text into CSV form.

Usage: blotter_to_accident_summary.py police_blotter.txt... > accidents.csv

"""

import csv
import fileinput
import re
import sys

def main():
    # Open a CSV file for writing and write its header row.
    csv_out = csv.writer(sys.stdout)
    csv_out.writerow('date time vehicles injuries tows location text'.split())
    # Read the police blotters and emit each accident as a new row.
    for description in get_accident_descriptions(fileinput.input()):
        csv_out.writerow(parse_accident_description(description))

def get_accident_descriptions(lines):
    """Get the lines from the ACCIDENTS section of the police blotter."""
    in_accident_section = False
    for line in lines:
        if not in_accident_section:
            # The accident section starts with a header.
            if re.match('ACCIDENT', line):
                in_accident_section = True
        else:
            # The accident section ends with an empty line.
            if not re.search(r'\w', line):
                in_accident_section = False
                continue
            # Every line within the section is an accident description.
            yield line

def parse_accident_description(line):
    """Parse a description of an accident.

    Returns:
      A (date, time, num_vehicles, num_injuries, num_tows, location, text)
      tuple if the line could be parsed; None otherwise.

    Example lines:
    Robb Hollow Road – Pedestrian stuck by vehicle in parking lot. 04/23/13 1425
    Sunset Drive – 2 vehicles, 1 injury, 2 tows. 04/23/13 1511
    Cochran Road – Hit & Run, vehicle struck at stop light. 04/25/13 0916

    """
    line = line.decode('utf8').replace(u'\u00a0', ' ').replace(u'\u2013', '-')
    match = re.match(ACCIDENT_DESCRIPTION_RE, line, re.U)
    if match:
        location, text, mm, dd, yy, time = match.groups()
        # Reformat date and time as YYYY-MM-DD HH:MM.
        date = '20{}-{}-{}'.format(yy, mm, dd)
        time = '%s:%s' % (time[:2], time[2:])
        # Get the # vehicles, tows, and injuries from the text.
        def get_value(unit, default):
            match = re.search(r'(\d+)\s+' + unit, text)
            return match.group(1) if match else default
        vehicles = get_value('vehicle', '1')
        injuries = get_value('injur', '0')
        tows = get_value('tow', '0')
        # Return the final row.
        return date, time, vehicles, injuries, tows, location, text
    raise Exception('Bad parse: ' + line.encode('utf8'))

ACCIDENT_DESCRIPTION_RE = r'(.*?)\s+-\s+(.*?)\s+(\d\d)/(\d\d)/(\d\d)\s+(\d{4})'

if __name__ == '__main__':
    main()
