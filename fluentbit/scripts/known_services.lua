local known_services = {
    ["fluentbit"] = "fluentbit",
    ["grafana"] = "grafana",
    ["react-app"] = "react-app",
    ["frontend"] = "frontend",
    ["nginx"] = "nginx",
    ["loki"] = "loki",
    ["apache2"] = "apache2",
}

local services = {
    "fluentbit",
    "grafana",
    "react-app",
    "frontend",
    "nginx",
    "loki",
    "apache2",
}

return known_services, services
