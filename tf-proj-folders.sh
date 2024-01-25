#!/bin/bash

# Define the base directory name
BASEDIR="terraform-project"

# Create the base directory
mkdir -p "$BASEDIR"

# Create the primary directories within the base directory
mkdir -p "$BASEDIR"/{modules,module1,module2}
mkdir -p "$BASEDIR"/environments/{staging,production}

# Echo the structure for confirmation
echo "Terraform project structure created in $BASEDIR"

