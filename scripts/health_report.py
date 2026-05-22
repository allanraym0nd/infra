import os
import socket

import boto3
import psutil


# Get instance ID from EC2 metadata
def get_instance_id():
    try:
        import urllib.request

        url = "http://169.254.169.254/latest/meta-data/instance-id"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=2) as response:
            return response.read().decode()
    except Exception:
        return "unknown"


def get_metrics():
    return {
        "cpu": psutil.cpu_percent(interval=1),
        "memory": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage("/").percent,
    }


def send_to_cloudwatch(instance_id, metrics):
    client = boto3.client("cloudwatch", region_name="us-east-1")

    metric_data = [
        {
            "MetricName": "CPUUsage",
            "Dimensions": [{"Name": "InstanceId", "Value": instance_id}],
            "Value": metrics["cpu"],
            "Unit": "Percent",
        },
        {
            "MetricName": "MemoryUsage",
            "Dimensions": [{"Name": "InstanceId", "Value": instance_id}],
            "Value": metrics["memory"],
            "Unit": "Percent",
        },
        {
            "MetricName": "DiskUsage",
            "Dimensions": [{"Name": "InstanceId", "Value": instance_id}],
            "Value": metrics["disk"],
            "Unit": "Percent",
        },
    ]

    client.put_metric_data(Namespace="CustomMetrics/EC2", MetricData=metric_data)

    print(f"Metrics sent for instance {instance_id}")
    print(f"   CPU:    {metrics['cpu']}%")
    print(f"   Memory: {metrics['memory']}%")
    print(f"   Disk:   {metrics['disk']}%")


if __name__ == "__main__":
    instance_id = get_instance_id()
    metrics = get_metrics()
    send_to_cloudwatch(instance_id, metrics)
