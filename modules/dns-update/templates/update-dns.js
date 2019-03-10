'use strict';

const AWS = require('aws-sdk')
const ec2 = new AWS.EC2()
const route53 = new AWS.Route53();

exports.handler = async (event, context, callback) => {
  const clusterArn = '${cluster_arn}'
  const serviceName = '${ecs_service_name}'
  const payload = event.detail
  const target_status = 'RUNNING'

  if (
    payload.desiredStatus !== target_status ||
    payload.lastStatus !== target_status
  ) {
    return
  }

  if (
    payload.clusterArn !== clusterArn ||
    !payload.group.includes(serviceName)
  ) {
    const message = ['Warning: service:', serviceName, 'cluster:', clusterArn]
    return callback(message.join(' '), {})
  }

  const eni = getEniAttachmentDetail(payload.attachments)

  if (!eni.length) {
    return callback('Fatal: unable to retrieve network interface', {})
  }

  const data = await ec2
    .describeNetworkInterfaces({
      NetworkInterfaceIds: [eni[0].value]
    })
    .promise()

  const networks = data.NetworkInterfaces.pop()

  if (!networks.Association.PublicIp) {
    return callback('Fatal: unable to retrieve public IP')
  }

  const result = await applyIpChange(networks.Association.PublicIp)
  
  if (!result.ChangeInfo.Status) {
    return callback('Fatal: '+JSON.stringify(result), {})
  }
  
  console.log(result)
  return;
}

const getEniAttachmentDetail = function (attachments) {
  const network = attachments.filter(function (attachment) {
    return attachment.type === 'eni'
  })

  if (network.length) {
    return network[0].details.filter(function (detail) {
      return detail.name === 'networkInterfaceId'
    })
  }

  return []
}

const applyIpChange = async function (ipAddress) {
  const domain = '${task_domain_name}'
  const hostedZoneId = '${route53_hosted_zone_id}'

  const changes = {
    HostedZoneId: hostedZoneId,
    ChangeBatch: {
      Changes: [
        {
          Action: 'UPSERT',
          ResourceRecordSet: {
            Name: domain,
            Type: 'A',
            TTL: ${domain_ttl},
            ResourceRecords: [{ Value: ipAddress }]
          }
        }
      ],
      Comment: 'Triggered by: ${function_name}'
    }
  }

  const result = await route53.changeResourceRecordSets(changes).promise()
  return result
}
