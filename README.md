# repository-access-fix
Scripts to add students as collaborators back to their own Github Repositories, after The GitHub Classroom Bug Of September 2024

## The Yikes:

When accepting an assignment on GitHub Classroom, students got a "Repository Access Issue" error, stating they no longer have access to their assignment repository. And to contact their teacher for support. But who are the teachers going to contact? Who is the me going to contact? (Thanks to the github community that also complained about this so I knew it wasn't just my fault)

## The Tea: 
### The repositories were actually created, and still there in the organization. The students were just not collaborators on them. How convenient.

With < 10 students, it would probably not suck to add them back manually to give them write access to their own repositories. But everyone's studying CS nowadays. These are scripts to fix. I found most of this online/on other forums and modified it to get it to work for us. If you somehow find this first, hope it helps.

You'll need [GitHub CLI](https://docs.github.com/en/education/manage-coursework-with-github-classroom/teach-with-github-classroom/using-github-classroom-with-github-cli), maybe you're like me and [have to download it](https://github.com/cli/cli#installation).

We're going to be [adding collaborators](https://docs.github.com/en/rest/collaborators/collaborators?apiVersion=2022-11-28#add-a-repository-collaborator) using the API.

You'll also want to find the affected assignment's ID, it was a 5 digit number:
```bash
gh classroom assignment
```
Use the arrow keys to navigate to the right assignment if you have a bunch of classrooms and assignments.

Or you can also do:
```bash
gh classroom assignments
```
Keep that lil number safe we'll need it in a second.

In this repo:
- ```add-collaborator.py``` (probably dont have to change anything here)
- ```find-collaborator.sh``` (update the format of the repo naming convention)
    - Under ```#Check if the user is a collaborator```, replace ```{repo}``` and ```{projectname}``` with your own organization naming style
    - Same for the ```echo gh api -X PUT...``` line
```bash
#!/bin/bash
assignmentID="$1"
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
  
  # Capture the accepted repositories list and filter it to only lines with repository URLs
  accepted_repos=$(eval "${command}" | awk '{if ($6 ~ /https/) print $5, $6}')
  [[ -z "${accepted_repos}" ]] && break
  
  # Process each line (which should now be "username repo_url")
  while read -r user repo; do
    # Check if the user is a collaborator
    check_command="gh api /repos/{repo}/{projectname}-${user}/collaborators/${user}"
    
    # If the user is not a collaborator, add the gh api command to the output file
    if ! eval "${check_command}" >/dev/null 2>&1; then
      echo "gh api -X PUT /repos/{repo}/{projectname}-${user}/collaborators/${user} &" >> ${output_file}
      echo "${user} is not a collaborator on their own repo (${repo})"
    fi
  done <<< "${accepted_repos}"
  
  ((i++))
done

# Add a wait command to ensure the script waits for all background tasks to finish
echo "wait" >> ${output_file}

echo "The commands have been written to ${output_file}. You can run it to grant write access."
```

Then, call
```./find-collaborator.sh```

It should output the affected users. In our case, some were affected, and others not.

A new file, ```grant-write-access.sh``` should be created. 

Run ```./grant-write-access.sh``` – It may take a second, I was lowkey pressed because I didn't know if I was breaking everything. If you get a permission denied error: do 
```bash
chmod +x grant-write-access.sh
```

Badabing Badaboom we ```bashed``` it till it worked (hehe), and the students should all have access to their repos again. Hopefully.
