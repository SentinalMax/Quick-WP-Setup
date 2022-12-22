# Quick Wordpress Setup
```
version: 1.17
```
This program is to be used on **headless linux machines**, but can be run on desktop Debian installations (such as Ubuntu) as well. 

See a full installation step guide here: https://github.com/zthiel1031/wordpress

**USAGE:**

```
git clone https://SentinalMax/Quick-WP-Setup.git
```
```
cd Quick-WP-Setup
```
```
sudo chmod +x qwp-setup.sh
```
```
bash qwp-setup.sh
```

Follow all prompts!

---
Adding a domain name to your wordpress site
---
For **GoDaddy** domains see: https://www.godaddy.com/help/edit-my-domain-nameservers-664

For **Others** follow this guide: https://sitebeginner.com/domains/domaintosite/
```
1. Follow the above guides to point your NS records from your hosting provider to whatever cloud service you might be using. (if not using a cloud instance ignore this step and continue on)
```
```
2. Access your DNS Configuration and change your 'A' or 'Root' Record, to point to your server's IP address. (make sure apache2 is running on port 80 & is web-facing)
```
```
3. In your DNS Config, change your CNAME to 'www.mywebsite.com' <- or whatever top-level-domain you're using
```
**(This step is on command line)**
```
nano /etc/httpd/conf/httpd.conf
```
OR
```
nano /etc/apache2/apache2.conf
```
```
4. Once nano'd into your apache configuration file, you'll want to edit the following:
```
**ServerAdmin** webmaster@localhost ***<- this will be the server admin's email***

**DocumentRoot** /var/www/html/wordpress ***<- if your wordpress installation is in this location, leave it!***
```
5. You'll want to add the following below '#LogLevel info ssl:warn'
```
**ServerName** mywebsite.com ***<- this will be the website domain name***

**ServerAlias** www.mywebsite.com ***<- this will be your domain CNAME (the www)***
```
6. sudo systemctl restart apache2.service
```
---
For SSL certification, needs a custom domain name
---

```
sudo apt-get update
```
```
sudo apt install certbot python3-certbot-apache
```
```
sudo certbot --apache
```
