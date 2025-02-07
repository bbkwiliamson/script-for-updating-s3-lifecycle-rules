#!/bin/bash

# Path to the new lifecycle JSON file
LIFECYCLE_JSON="example-lifecycle-rule.json"

# Get a list of all S3 buckets in your AWS account
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and update the lifecycle policy
for BUCKET in $BUCKETS; do
    echo "🔄 Processing bucket: $BUCKET"

    # Fetch existing lifecycle configuration (if any)
    EXISTING_RULES=$(aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET" --query "Rules" --output json 2>/dev/null)

    # If no existing rules, apply new rules directly
    if [[ -z "$EXISTING_RULES" || "$EXISTING_RULES" == "null" ]]; then
        echo "No existing lifecycle rules found for $BUCKET. Applying new rules."
        MERGED_RULES=$(jq '.Rules' "$LIFECYCLE_JSON")
    else
        echo "Merging existing rules with new rules for $BUCKET."

        # Get the new rules
        NEW_RULES=$(jq '.Rules' "$LIFECYCLE_JSON")

        # Merge logic: Update only matching rule IDs, keep others unchanged
        MERGED_RULES=$(jq -n --argjson existing "$EXISTING_RULES" --argjson new "$NEW_RULES" '
            # Build a map of new rules by ID
            $new | map({(.ID): .}) | add as $newMap |

            # Iterate over existing rules, updating those that match new IDs
            $existing | map(
                if .ID and ($newMap[.ID] != null) then
                    $newMap[.ID]  # Replace with updated rule
                else
                    .  # Keep existing rule unchanged
                end
            ) + 

            # Append any new rules that do not exist in the original rules
            ($new | map(select(.ID as $id | $existing | all(.ID != $id))))
        ')

        # Ensure merged rules are valid
        if [[ -z "$MERGED_RULES" || "$MERGED_RULES" == "null" ]]; then
            echo "❌ Error: Merged rules are empty! Skipping $BUCKET."
            continue
        fi
    fi

    # Apply the merged lifecycle configuration
    echo "Applying updated lifecycle policy to $BUCKET..."
    echo "{ \"Rules\": $MERGED_RULES }" > final_lifecycle.json
    aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET" --lifecycle-configuration file://final_lifecycle.json

    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully updated lifecycle policy for $BUCKET"
    else
        echo "❌ Failed to update lifecycle policy for $BUCKET"
    fi
done

echo "✅ Lifecycle policy update completed for all buckets."

