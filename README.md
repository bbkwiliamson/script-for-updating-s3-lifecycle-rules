# script-for-updating-s3-lifecycle-rules


the **delete-lifecycle-rule.sh ** 
  = this file is for deleting a specific lifecycle rule in a bucket while making sure that all other existing rules that are there remain.

the ****updating-s3-lifecycle.sh**
  = this file is for updating the buckets with lifecycle rules specified in a .json file
  = NOTE: both of the files {example-lifecycle-rule.json,updating-s3-lifecycle.sh} must be on the same location or path.
         *the script checks for existing rules
          * then iterate through the rules and look for matching IDs
          * if there is any rule with a matching ID, it gets updated with the new details from the .json file
          * if there are no such, the rules remain as they are
          * and if the provided .json file comes with a new rule which is not currently on the bucket, the rule gets added

  to execute the .sh files.
      you first need to change the permissions by running: chmod +x name-of-the-file      then click ENTER
      then run: ./{.sh file}    you click enter to execute the script  
