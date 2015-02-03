#
# Cookbook Name:: sails-task-mere
# Recipe:: default
#
# Copyright 2015, Mere Technology, llc
# MIT license
#



##configure user
# Create a sails OS account with the users cookbook
user 'sails-task-mere' do
  comment node[:sailsTaskMere][:user]
  shell '/bin/bash'
  home node[:sailsTaskMere][:home]
  action :create
end

# Create home directory
directory '/home/sails-task-mere' do
  owner node[:sailsTaskMere][:user]
  group node[:sailsTaskMere][:user]
  mode '0755'
end

#configure the compass/sass dependencies
node.default['rbenv']['user_installs'] = [
  { 'user'    => node[:sailsTaskMere][:user],
    'rubies'  => [node[:sailsTaskMere][:rbenv_version] ],
    'global'  => node[:sailsTaskMere][:rbenv_version] ,
    'gems'    => {
      '2.1.2'    => [
        { 'name'    => 'sass' },
        { 'name'    => 'compass' }
      ]
    }
  }
]


include_recipe 'rbenv::user'


## Grab Source
git node[:sailsTaskMere][:app_dir] do
  user node[:sailsTaskMere][:user]
  group node[:sailsTaskMere][:user]
  repository "#{node[:sailsTaskMere][:repository]}"
  revision "master"
  action :sync
end

#Node JS dependencies

execute "npm install -g npm@#{node[:sailsTaskMere][:npm_version]}" do
  user 'root'
  not_if "npm --version | grep -q '#{node[:sailsTaskMere][:npm_version]}' "
end

execute "npm install -g bower@#{node[:sailsTaskMere][:bower_version]}" do
  user 'root'
  not_if "bower --version | grep -q '#{node[:sailsTaskMere][:bower_version]}' "
end

execute "npm install -g forever@#{node[:sailsTaskMere][:forever_version]}" do
  user 'root'
  not_if "forever --version | grep -q '#{node[:sailsTaskMere][:forever_version]}' "
end

execute "npm install -g sails@#{node[:sailsTaskMere][:sails_version]}" do
  user 'root'
  not_if "sails --version | grep -q '#{node[:sailsTaskMere][:sails_version]}' "
end




execute "bower install --config.interactive=false" do
  user node[:sailsTaskMere][:user]
  group node[:sailsTaskMere][:user]
  cwd node[:sailsTaskMere][:app_dir]
  environment ({'HOME' => '/home/sails-task-mere'})
end

execute "npm install" do
  user node[:sailsTaskMere][:user]
  group node[:sailsTaskMere][:user]
  cwd node[:sailsTaskMere][:app_dir]
  environment ({'HOME' => '/home/sails-task-mere'})
end

## configure service

## configuration files
template "/etc/systemd/system/#{node[:sailsTaskMere][:user]}.service" do
  source 'sailsTaskMere.service'
  mode 0644
  owner "root"
  group "wheel"
end

directory "#{node[:sailsTaskMere][:home]}/run" do
  owner node[:sailsTaskMere][:user]
  group node[:sailsTaskMere][:user]
  mode '0744'
  action :create
end

execute "systemctl enable /etc/systemd/system/#{node[:sailsTaskMere][:user]}.service" do
  user 'root'
  not_if "systemctl status #{node[:sailsTaskMere][:user]}.service | grep -q 'not-found'"
end

## configuration files
cookbook_file "www.conf" do
  path "/etc/nginx/conf.d/dev.conf"
    notifies :restart, 'service[nginx]', :delayed
  action :create
end




