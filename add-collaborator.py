import sys
for line in sys.stdin:
    parts = line.split('\t')
    user = parts[-2].strip()
    url = parts[-1].strip()
    urlparts = url.split('/')
    org = urlparts[-2]
    repo = urlparts[-1]
    print(f'gh api -XPUT /repos/{org}/{repo}/collaborators/{user}')
