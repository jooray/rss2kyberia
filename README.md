rss2kyberia
===========

A script to post RSS feeds to kyberia.sk

I always wanted to do this, because I was jealous of other people having their personal notepads on Kyberia and they could get K!s :). Ok, not really, but here it is. Probably first Kyberia.sk automated integration.   
  
[![][1]][2]  
  
So, what it does? It checks RSS feed of my Soup (jooray.soup.io, may be obsolete now) and posts it to kyberia.sk under my node.
  
It is written in Ruby.
  
Kyberia is poor at writing error messages, so if you don't have enough Ks to post, or so, it will just silently not post the message.   
  
If there is indeed an error, it will e-mail you with the problem and won't try to post again.  
  
It's possible to limit number of posts written in one run, but if you are active on Soup, you can easily get far beyond the K limit.  
  
It uses SQLite3 to remember which posts it already uploaded.  
  
Install instructions in the source code (in the beginning), also with instructions to get all the gems.  
  
After configuring it (your ID, password, node id where to post to), just put it in your cron and it does the work.  
  
It seems, that Kyberia allows multiple logins (with different session IDs) and logging in later does not cancel your previous session. That's great.  
  
I found an ugly bug in Kyberia, that literally took most of my Ks in my K-wallet, because it is very unintuitive -- in K-wallet upload setting, there is a number of Ks you have there. But if you click "upload", it uploads that number. So basically one click can upload all Ks from K-wallet to your current K buffer, but there's an upper limit of 123. So: I have 10 Ks in my K-wallet and 123 to post (at least I imported some backlog via Soup's RSS export feature). 700 Ks gone. I can't say I'm said, because until now, I never knew about K-wallet and other such stuff....

Bitcoin donations welcome at **19bHgttUiWtWU6ifzdpdvnu4hqcUZQPFoA**

  [1]: http://flz.sk.cx/rss2kyberia-small.png
  [2]: http://flz.sk.cx/rss2kyberia.png

