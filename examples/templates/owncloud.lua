#!/usr/sbin/container

owncloud={}
owncloud.instances={}

function owncloud:Instance(website)
	if not website then website = {} end
	if not website.root then website.root='/owncloud/' .. website.hostname .. '/' end
	if not website.rewrites then website.rewrites={} end
	if not website.redirects then website.redirects={} end
	
	website.rewrites['^/index.php/.*$'] = {source='^/index.php/.*$', target='/index.php?{query}'}
	website.rewrites['^/remote.php/(webdav|caldav|carddav|dav)(\\/?)$'] = {source='^/remote.php/(webdav|caldav|carddav|dav)(\\/?)$', target='/remote.php/{1}'}
	website.rewrites['^/remote.php/(webdav|caldav|carddav|dav)/(.+?)(\\/?)$'] = {source='^/remote.php/(webdav|caldav|carddav|dav)/(.+?)(\\/?)$', target='/remote.php/{1}/{2}'}
	website.rewrites['^/(?:\\.htaccess|data|config|db_structure\\.xml|README)'] = {source='^/(?:\\.htaccess|data|config|db_structure\\.xml|README)', target='/404'}

	website.redirects['/.well-known/carddav'] = {source='/.well-known/carddav', target='/remote.php/carddav', status=301}
	website.redirects['/.well-known/caldav'] = {source='/.well-known/caldav', target='/remote.php/caldav', status=301}

	owncloud.instances[website.root] = owncloud.instances
	
	return website
end

function install_container()
	print("Installing ownCloud.")
	write_file("/etc/apt/sources.list.d/owncloud.list", "deb http://download.owncloud.org/download/repositories/9.0/Debian_8.0/ /")
	install_package("ca-certificates")
	exec("wget -nv https://download.owncloud.org/download/repositories/9.0/Debian_8.0/Release.key -O /dev/stdout -o /dev/null | apt-key add - ")
	exec("apt-get update")
	install_package("owncloud-files")
	print("Saving cache...")
	exec("cd /var/www/owncloud; tar -jcf /var/cache/owncloud.cache *")
	if mysql and mysql.password then
		exec('mkdir /var/run/mysqld/ ; chmod 0777 /var/run/mysqld/; mysqld & sleep 5')
		exec('mysql -uroot -p"' .. mysql.password .. '" -e "CREATE DATABASE owncloud;"')
	end
	for path, instance in pairs(owncloud.instances) do
		if path ~= "/var/www/owncloud/" and path ~= "/var/www/owncloud" then
			print("Installing ownCloud in " .. path)
			exec("mkdir -p ./" .. path)
			exec("cd ./" .. path .."; tar --skip-old-files -kjxf /var/cache/owncloud.cache")
			exec("chown www-data:www-data -R ./" .. path)
		end
	end
end

if not filesystem['/owncloud/'] then filesystem['/owncloud/'] = { type="map", path="owncloud" } end
if not filesystem['/var/www/owncloud/'] then filesystem['/var/www/owncloud/'] = { type="map", path=".default-owncloud" } end

