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
      Job.new(job["name"], job["color"])
    end

    jobs
  end

  private

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
