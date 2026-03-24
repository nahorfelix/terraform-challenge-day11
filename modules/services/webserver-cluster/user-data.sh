#!/bin/bash
yum update -y
yum install -y httpd

cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html><head><title>${cluster_name}</title></head>
<body><h1>${cluster_name}</h1><p>Port ${server_port}</p></body></html>
EOF

systemctl start httpd
systemctl enable httpd
sed -i "s/Listen 80/Listen ${server_port}/" /etc/httpd/conf/httpd.conf
systemctl restart httpd
