#!/usr/bin/env ruby

require 'httparty'
require 'dotenv'
require 'json'
require_relative 'job'

Dotenv.load

class JenkinsAdapter
  def initialize(user, token)
    @user = user
    @token = token
  end

  def main
    interesting_builds.map do |build_name|
      frontend_uri = "https://#{hostname}/job/#{build_name}/api/json"

      response = authenticated_request(frontend_uri)

      builds = response["builds"]

      latest_build = builds.sort_by { |build| build["number"] }.last

      [build_name, authenticated_request("#{latest_build["url"]}/api/json")]
    end
  end

  def all_builds
    frontend_uri = "https://#{hostname}/api/json"

    response = authenticated_request(frontend_uri)

    jobs = response['jobs'].map do |job|
      percentage = if job['color'] =~ /_anime$/
                     get_build_percentage(job)
                   else
                     0
                   end

      Job.new(job['name'], job['color'], percentage)
    end

    jobs
  end

  private

  def get_build_percentage(job)
    job_url = "#{job['url']}/api/json"
    job_data = authenticated_request(job_url)

    current_build_url = "#{job_data['builds'].first['url']}/api/json"

    build_data = authenticated_request(current_build_url)

    build_timestamp_in_ms = build_data['timestamp']
    build_start_time = Time.at(build_timestamp_in_ms / 1000)

    current_duration = (Time.now - build_start_time)
    estimated_duration = (build_data['estimatedDuration'] / 1000)

    percentage = (current_duration / estimated_duration) * 100

    percentage.round
  end

  def authenticated_request(uri)
    response = HTTParty.get(uri, basic_auth: {
      username: @user,
      password: @token
    })

    JSON.parse(response.body)
  end

  def interesting_builds
    ENV.fetch("JENKINS_BUILDS").split(",").map(&:strip)
  end

  def hostname
    ENV.fetch("JENKINS_HOSTNAME").strip
  end
end
