# config valid only for current version of Capistrano
lock "3.9.0"


# Bundler
set :bundle_roles, :web
set :bundle_without, 'development test'

# RBEnv
set :rbenv_type, :system
set :rbenv_ruby, '2.3.3'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :web
set :default_environment, { 'PATH' => '/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH' }

set :application, "monitoring"
set :repo_url, "git@github.com:Jumba/monit-xml-parsing.git"

set :ssh_options, { :forward_agent => true }

set :linked_files, [".env"]

set :passenger_restart_with_touch, true
