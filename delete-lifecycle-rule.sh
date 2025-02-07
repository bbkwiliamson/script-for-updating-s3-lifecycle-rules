#!/bin/bash

# ID of the rule to delete
RULE_ID_TO_DELETE="NoncurrentVersionsToGlacierSmallObjects2"

# Get a list of all S3 buckets in your AWS account
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and update the lifecycle policy
for BUCKET in $BUCKETS; do
    echo "Processing bucket: $BUCKET"

    # Fetch existing lifecycle configuration (if any)
    EXISTING_RULES=$(aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET" --query "Rules" --output json 2>/dev/null)

    # If the bucket has no existing rules, skip it
    if [ -z "$EXISTING_RULES" ] || [ "$EXISTING_RULES" == "null" ]; then
        echo "No existing lifecycle rules found for $BUCKET. Skipping."
        continue
    fi

    echo "Removing rule with ID: $RULE_ID_TO_DELETE from $BUCKET."

    # Remove the rule with the matching ID
    UPDATED_RULES=$(echo "$EXISTING_RULES" | jq --arg RULE_ID "$RULE_ID_TO_DELETE" 'del(.[] | select(.ID == $RULE_ID))')

    # Ensure updated rules are valid
    if [ -z "$UPDATED_RULES" ] || [ "$UPDATED_RULES" == "null" ]; then
        echo "Error: No rules found after deletion for $BUCKET. Skipping."
        continue
    fi

    # Apply the updated lifecycle configuration
    echo "Applying updated lifecycle policy to $BUCKET..."
    echo "{ \"Rules\": $UPDATED_RULES }" > final_lifecycle.json
    aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" --lifecycle-configuration file://final_lifecycle.json

    if [ $? -eq 0 ]; then
        echo "✅ Successfully deleted rule for $BUCKET"
    else
        echo "❌ Failed to delete rule for $BUCKET"
    fi
done

echo "✅ Lifecycle rule deletion completed for all buckets."

