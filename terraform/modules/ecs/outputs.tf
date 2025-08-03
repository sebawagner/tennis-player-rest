output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.tennis_player_cluster.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.tennis_player_cluster.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.tennis_player.name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.tennis_player_alb.dns_name
}

output "alb_url" {
  description = "URL of the application"
  value       = "http://${aws_lb.tennis_player_alb.dns_name}"
}
