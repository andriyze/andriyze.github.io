10.10.10.40 - blue
nmap -A 10.10.10.40
We have Windows 7 Pro 7601 SP1
ports 135 445 are open
1/7We can try to scan it for vulns with nmap
nmap --script vuln -p 445 10.10.10.40
Looks like we have Eternal Blue here: MS17-010
We can check what we have on SMB
smbclient -L 10.10.10.40
Try accessing Users share
smbclient //10.10.10.40/Users
2/7This share is accessible without password.
Let's copy this repo
https://github.com/worawit/MS17-010
will run checker.py
3/7All named pipes are denied. Mist eternal blue scripts won't work here.
Searching eternal blue and Windows version 7601 gives us this
https://www.exploit-db.com/exploits/42315
To use the script we need two things:
1. prepare a reverse shell
2. edit script for our needs.
a). edit username variable to use share without the password (guest authentication)
b). specify location for our reverse shell that we generated
4/7Let's run the script
While listenning on port 4444 locally
5/7We got shell and we are nt authority.
Now we can get root flag
root
ff548eb71e920ff6c08843ce9df4e717
And user flag
6/7user
4c546aea7dbee75cbd71de245c8deea9
7/7
