set :env, 'staging'
set :user, 'apphoster'
set :deploy_to, "/home/#{fetch(:user)}/rails_apps/#{fetch(:env)}/#{fetch(:application)}"
set :ssh_options, { :forward_agent => true }
set :branch, ->() {
  default_branch = "master"

  $stdout.write "Deploy branch [#{default_branch}] "

  response = $stdin.gets.strip

  if response.empty?
    default_branch
  else
    response
  end
}
set :keep_releases, 2

server "stg-srv001.staging.local", roles: [:web], user: 'apphoster', primary: true
after 'deploy', 'deploy:restart'

