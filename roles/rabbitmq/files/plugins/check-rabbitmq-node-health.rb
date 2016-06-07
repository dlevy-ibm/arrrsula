#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ check node health plugin
# ===
#
# DESCRIPTION:
# This plugin checks if RabbitMQ server node is in a running state.
#
# The plugin is based on the RabbitMQ cluster node health plugin by Tim Smith
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: rest-client
#
# LICENSE:
# Copyright 2012 Abhijith G <abhi@runa.com> and Runa Inc.
# Copyright 2014 Tim Smith <tim@cozy.co> and Cozy Services Ltd.
# Copyright 2015 Edward McLain <ed@edmclain.com> and Daxko, LLC.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'sensu-plugin/utils'
require 'json'
require 'rest_client'

include Sensu::Plugin::Utils

# main plugin class
class CheckRabbitMQNodeHealth < Sensu::Plugin::Check::CLI
  user = settings['rabbitmq'][0]['user'] rescue settings['rabbitmq']['user']
  password = settings['rabbitmq'][0]['password'] rescue settings['rabbitmq']['password']

  option :host,
         description: 'RabbitMQ host',
         short: '-h',
         long: '--host HOST',
         default: 'localhost'

  option :username,
         description: 'RabbitMQ username',
         short: '-u',
         long: '--username USERNAME',
         default: user

  option :password,
         description: 'RabbitMQ password',
         short: '-p',
         long: '--password PASSWORD',
         default: password

  option :port,
         description: 'RabbitMQ API port',
         short: '-P',
         long: '--port PORT',
         default: '15672'

  option :warning,
         description: 'Warning value for all checks',
         short: '-w',
         long: '--warn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :critical,
         description: 'Critical value for all checks',
         short: '-c',
         long: '--crit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :memwarn,
         description: 'Warning % of mem usage vs high watermark',
         long: '--mwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :memcrit,
         description: 'Critical % of mem usage vs high watermark',
         long: '--mcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :fdwarn,
         description: 'Warning % of file descriptor usage vs high watermark',
         long: '--fwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :fdcrit,
         description: 'Critical % of file descriptor usage vs high watermark',
         long: '--fcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :socketwarn,
         description: 'Warning % of socket usage vs high watermark',
         long: '--swarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :socketcrit,
         description: 'Critical % of socket usage vs high watermark',
         long: '--scrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :procwarn,
         description: 'Warning % of procs usage vs high watermark',
         long: '--pwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :proccrit,
         description: 'Critical % of procs usage vs high watermark',
         long: '--pcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :watchalarms,
         description: 'Sound critical if one or more alarms are triggered',
         short: '-a BOOLEAN',
         long: '--alarms BOOLEAN',
         default: 'true'

  def run
    res = node_healthy?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'warning'
      warning res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def node_healthy?
    host     = config[:host]
    port     = config[:port]
    username = config[:username]
    password = config[:password]

    begin
      message = ""
      status = ""
      critical = 0
      warning =  0

      resource = RestClient::Resource.new "http://#{host}:#{port}/api/nodes", username, password
      # Parse our json data
      nodeinfo = JSON.parse(resource.get)[0]

      # Determine % memory consumed
      mem = format('%.2f', nodeinfo['mem_used'].fdiv(nodeinfo['mem_limit']) * 100)
      # Determine % sockets consumed
      socket = format('%.2f', nodeinfo['sockets_used'].fdiv(nodeinfo['sockets_total']) * 100)
      # Determine % file descriptors consumed
      fd = format('%.2f', nodeinfo['fd_used'].fdiv(nodeinfo['fd_total']) * 100)
      # Determine % procs consumed
      procs = format('%.2f', nodeinfo['proc_used'].fdiv(nodeinfo['proc_total']) * 100)

      if mem.to_f >= config[:memcrit] or mem.to_f >= config[:critical]
        message += " Memory Critical: #{mem}%"
        critical = critical + 1   
      elsif mem.to_f >= config[:memwarn] or mem.to_f >= config[:warning]
        message += " Memory Warning: #{mem}%"
        warning = warning + 1
      end

      if socket.to_f >= config[:socketcrit] or socket.to_f >= config[:critical]
        message += " Sockets Critical: #{socket}%"
        critical = critical + 1   
      elsif socket.to_f >= config[:socketwarn] or socket.to_f >= config[:warning]
        message += " Sockets Warning: #{socket}%"
        warning = warning + 1
      end

      if fd.to_f >= config[:fdcrit] or fd.to_f >= config[:critical]
        message += " FD Critical: #{fd}%"
        critical = critical + 1   
      elsif fd.to_f >= config[:fdwarn] or fd.to_f >= config[:warning]
        message += " FD Warning: #{fd}%"
        warning = warning + 1
      end

      if procs.to_f >= config[:proccrit] or procs.to_f >= config[:critical]
        message += " Procs Critical: #{procs}%"
        critical = critical + 1   
      elsif procs.to_f >= config[:procwarn] or procs.to_f >= config[:warning]
        message += " Procs Warning: #{procs}%"
        warning = warning + 1
      end

      # build status and message
      crit_warn_message = "Critical(#{critical}) Warning(#{warning}) |"
      if message == ""
        status = 'ok'
        message = "Server is healthy"
      elsif critical > 0
        message = crit_warn_message + message
        status = 'critical'
      else
        message = crit_warn_message + message
        status = 'warning'
      end

      # If we are set to watch alarms then watch those and set status and messages accordingly
      if config[:watchalarms] == 'true'
        if nodeinfo['mem_alarm'] == true
          status = 'critical'
          message += ' Memory Alarm ON'
        end

        if nodeinfo['disk_free_alarm'] == true
          status = 'critical'
          message += ' Disk Alarm ON'
        end
      end

      { 'status' => status, 'message' => message }
      rescue Errno::ECONNREFUSED => e
      { 'status' => 'critical', 'message' => e.message }
      rescue => e
      { 'status' => 'unknown', 'message' => e.message }
    end
  end
end
