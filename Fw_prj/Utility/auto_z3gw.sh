#!/bin/sh -e
echo "Running Z3gateway" 
# Run z3gw from virtual environment
/home/pi/documents/Python/myenv/bin/python /home/pi/documents/Python/Fw_prj/z3gw.py /dev/ttyACM0 
echo "Done"
exit 0
#/home/pi/documents/Python/myenv/bin/activate