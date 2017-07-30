#
# Cookbook:: webserver
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
package 'httpd' do
  action :install
end

service 'httpd' do
  action [ :enable, :start ]
end

cookbook_file "/var/www/html/index.html" do
  source "index.html"
  mode "0644"
end

service 'firewalld' do
  action [ :enable, :start ]
end


execute 'web-firewalld' do
  command '/usr/bin/firewall-cmd  --permanent --zone public --add-service http --add-service https'
  ignore_failure true
end

execute 'reload-firewalld' do
  command '/usr/bin/firewall-cmd --reload'
  ignore_failure true
end

package "openssl" do
  action :install
end

# create output dir
directory node['selfsigned_certificate']['destination'] do
    owner "root"
    group "root"
    mode 0755
    action :create
    recursive true
end
# create the certificate: make a request for signature for a certiciate, and have your own CA sign it.
bash "selfsigned_certificate" do
  user "root"
  cwd node['selfsigned_certificate']['destination']
  code <<-EOH
        echo "Creating certificate ..."
        openssl genrsa -passout pass:#{node['selfsigned_certificate']['sslpassphrase']} -des3 -out server.key 1024
        openssl req -passin pass:#{node['selfsigned_certificate']['sslpassphrase']} -subj "/C=#{node['selfsigned_certificate']['country']}/ST=#{node['selfsigned_certificate']['state']}/L=#{node['selfsigned_certificate']['city']}/O=#{node['selfsigned_certificate']['org']}/OU=#{node['selfsigned_certificate']['depart']}/CN=#{node['selfsigned_certificate']['cn']}/emailAddress=#{node['selfsigned_certificate']['email']}" -new -key server.key -out server.csr
        cp server.key server.key.org
        openssl rsa -passin pass:#{node['selfsigned_certificate']['slpassphrase']} -in server.key.org -out server.key
        openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
        echo "Done #{node['selfsigned_certificate']['destination']}."
        EOH
end

