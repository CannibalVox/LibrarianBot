# Description
#  Custom hubot-deploy scripts for hipchat
#

module.exports = (robot) ->
  # Reply with the most recent deployments that the api is aware of
  #
  # msg - The hubot message that triggered the deployment. msg.reply and msg.send post back immediately
  # deployment - The deployed app that matched up with the request.
  # deployments - The list of the most recent deployments from the GitHub API.
  # formatter - A basic formatter for the deployments that should work everywhere even though it looks gross.
  robot.on "hubot_deploy_recent_deployments", (msg, deployment, deployments, formatter) ->
    msg.send formatter.message()

  # Reply with the environments that hubot-deploy knows about for a specific application.
  #
  # msg - The hubot message that triggered the deployment. msg.reply and msg.send post back immediately
  # deployment - The deployed app that matched up with the request.
  # formatter - A basic formatter for the deployments that should work everywhere even though it looks gross.
  robot.on "hubot_deploy_available_environments", (msg, deployment) ->
    msg.send "#{deployment.name} can be deployed to #{deployment.environments.join(', ')}."

  # An incoming webhook from GitHub for a deployment.
  #
  # deployment - A Deployment from github_events.coffee
  robot.on "github_deployment_event", (deployment) ->
    if deployment.notify
      user  = robot.brain.userForId deployment.notify.user
      deployment.actorName = user.name

    messageBody = deployment.toSimpleString().replace(/^hubot-deploy: /i, '')
    robot.logger.info messageBody
    if deployment?.notify?.room?
      robot.messageRoom deployment.notify.room, "Deploy Requested: Branch #{deployment.name}/#{deployment.ref} being deployed to #{deployment.environment}." 

  # An incoming webhook from GitHub for a deployment status.
  #
  # status - A DeploymentStatus from github_events.coffee
  robot.on "github_deployment_status_event", (status) ->
    if status.notify
      user  = robot.brain.userForId status.notify.user
      status.actorName = user.name

    if status.state != "success" && status.state != "failed"
      return
    messageBody = status.toSimpleString().replace(/^hubot-deploy: /i, '')
    robot.logger.info messageBody
    if status?.notify?.room?
      if status.state == "success"
        robot.messageRoom status.notify.room, "Deploy Complete: Restarting in 30 seconds."
      else
        robot.messageRoom status.notify.room messageBody

  robot.on "github_pull_request", (pullRequest) ->
    action = pullRequest.action
    if action == "closed" && pullRequest.merged
      action = "merged"
    value = "PR \##{pullRequest.number} #{action} by #{pullRequest.actor} on #{pullRequest.repoName}"
    if pullRequest.action == "opened"
      value += ": #{pullRequest.title}."
    
    value += " https://github.com/#{pullRequest.repoName}/pull/#{pullRequest.number}"
    robot.messageRoom '369872707648618496', value
