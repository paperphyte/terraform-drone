# Readme

Module creates public fargate tasks accessible from internet through shared pre-created aws lb.

## Argument Reference

 * ```vcp_id``` ID of vpc
 * ```vcp_private_subnets``` Private subnets to create task in
 * ```lb_target_group_id``` "Id of specific target group"
 * ```task_name``` Name of task container
 * ```task_image``` Name of task container image
 * ```task_image_version``` (Optional) Version of task container image
 * ```task_cpu``` (Optional) CPU of Fargate task
 * ```task_memory``` (Optional) Memory of Fargate task
 * ```task_container_cpu``` (Optional) cpu of Fargate task container
 * ```task_container_memory``` (Optional) memory of Fargate task container
 * ```task_container_log_group_name``` Name of log group for container
 * ```task_min_count``` (Optional) Minimum number of task containers
 * ```task_max_count``` (Optional) Maximum number of task containers
 * ```task_bind_port``` (Optional) Portmapping of task container port
 * ```task_secret_vars``` Secret environment vars for container
 * ```task_environment_vars``` (Optional) Environment vars for container
 * ```service_name``` Name of service
 * ```service_capacity_provider``` (Optional) Capacity provider of service
 * ```service_cluster_name``` Name of cluster for service
 * ```service_cluster_id``` ID of cluster for service
 * ```service_discovery_dns_namespace_id``` Service discovery private dns namespace id
 * ```mount_points``` (Optional) List of maps representing mount points with required attributes `containerPath`, `sourceVolume` and `readOnly
 * ```volumes``` (Optional) Volume blocks that containers can have
 * ```load_balancer``` (Optional) One loadbalancer definition in a list for dynamic block

## Attribute Reference

 * ```task_role_arn``` Role arn for task capabilities
 * ```service_sg_id``` ID of security group
