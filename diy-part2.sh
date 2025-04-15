#!/bin/bash

# Replace ash with bash
sed -i 's/\/bin\/ash/\/bin\/bash/' package/base-files/files/etc/passwd
