#!/bin/bash
assignmentID="$1"
repo_name="my_org" # Change this to the organization name
project_name="my_project" # Change this to the project title
output_file="grant-write-access.sh"

if [ -z "${assignmentID}" ]; then
  echo "Usage: ./find-collaborator.sh <assignmentID>"
  gh classroom assignments
  exit 1
fi

# Start fresh: create or overwrite the output file and make it executable
echo "#!/bin/bash" > ${output_file}
chmod +x ${output_file}

i=1
while : ; do
  command="gh classroom accepted-assignments -a ${assignmentID} --per-page 30 --page $i"
  echo "Running: ${command}"
  
  # Capture the accepted orgsitories list and filter it to only lines with orgsitory URLs
  accepted_orgs=$(eval "${command}" | awk '{if ($6 ~ /https/) print $5, $6}')
  [[ -z "${accepted_orgs}" ]] && break
  
  # Process each line (which should now be "username org_url")
  while read -r user repo; do
    # Check if the user is a collaborator
    check_command="gh api /repos/${repo_name}/${project_name}-${user}/collaborators/${user}"
    
    # If the user is not a collaborator, add the gh api command to the output file
    if ! eval "${check_command}" >/dev/null 2>&1; then
      echo "gh api -X PUT /repos/${repo_name}/${project_name}-${user}/collaborators/${user} &" >> ${output_file}
      echo "${user} is not a collaborator on their own repo (${repo})"
    fi
  done <<< "${accepted_repos}"
  
  ((i++))
done

# Add a wait command to ensure the script waits for all background tasks to finish
echo "wait" >> ${output_file}

echo "The commands have been written to ${output_file}. You can run it to grant write access."
