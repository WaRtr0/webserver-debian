[![LinkedIn][linkedin-shield]][linkedin-url] [![works badge](https://cdn.jsdelivr.net/gh/nikku/works-on-my-machine@v0.2.0/badge.svg)](https://github.com/nikku/works-on-my-machine)

<h1 align="center">Debian Web Server</h1>


[Debian](https://www.debian.org/) - [Apache](https://httpd.apache.org/) - [Nginx](https://nginx.org/) - [iRedMail](https://github.com/iredmail/iRedMail) - [certbot](https://certbot.eff.org/) - [Fail2ban](https://www.fail2ban.org/) - [Php](https://www.php.net/) - [NodeJs](https://nodejs.org/) - [Phusion Passenger](https://github.com/phusion/passenger)


# About

New project! I have been working in a Debian and [Plesk](https://www.plesk.com/) environment for a very long time.

But I decided to stop working with Plesk which does all the work for me 😅.

So I'm challenging myself to create a small tool to install a web server, with a complementary tools for example to add clients with a chroot that will host their sites...

I'm still a student so don't imagine a perfect thing, I count on your help to improve this project 😉

# Work environment

  Virutal Private Server of [Contabo](https://contabo.com/)
  
  - OS : Debian 11 (bullsere) x86_64
  - Shell : Bash 5.1.4
  - CPU : AMD EPYC 7282 (6) @ 2.799GHz
  - Memory :  16 GB

  Software
  
  - putty
  - nano 😂 & sublime/vs code

# Requirement
  
  Minimum Requirement
  
  - OS : Debian / ubuntu
  - Storage : 25Gb
  - Memory : 3 Gb
  - Fresh Server with ssh...
  
  Recommended Requirement
  
  - OS : Debian 11
  - Storage : 200 Gb
  - Memory : 8Gb

# Install

It is highly recommended to be a root user!

Install git to clone the script :
```
apt install git -y
```

Download the script :
```
git clone https://github.com/WaRtrO89/webserver-debian.git
```
Run the script
```
bash webserver-debian/install.sh
```

You have some questions at the beginning, please fill them in correctly, without spam on "enter" !

After these questions the script will install most of the things we need on the server. You can go have a little coffee 😂

Reboot your machine when the installation is complete
```
Reboot
```
For a question of security, I recommend you to disable the possibility to connect in ssh with a root user
For this go to :
```
nano /etc/ssh/sshd_config
```
and modify the line (121) where you have "PermitRootLogin yes" and replace "yes" by "no" then save & restart ssh service.
```
systemctl restart sshd
```
Finish, now you have to log in with the user that was created with the script.

# Contact

Discord : WaRtrO#6293

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/maxence-morot
