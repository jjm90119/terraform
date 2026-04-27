add-content -path c:/users/shin.joshua/.ssh/config -value @'

Host ${hostname}
    Hostname ${hostname}
    User ${user}
    IdentifyFile ${identityfile}
'@