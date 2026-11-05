%{ for server in servers ~}
Serveur : ${server.name} - IP : ${server.ip}
%{ endfor ~}