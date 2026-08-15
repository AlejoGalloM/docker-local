#!/bin/bash

# Este script crea el secreto en LocalStack usando awslocal dentro del contenedor

SECRET_NAME="nu1291001-conversor-contable-dev-secret-operative-eda-com-mnt"

SECRET_VALUE='{"username": "local-user", "password": "local-password", "bootstrapserver": "localhost:9095", "certificate.cer": "-----BEGIN CERTIFICATE-----\nMIIEXTCCAsWgAwIBAgIISHs/tzN4ohowDQYJKoZIhvcNAQEMBQAwXTELMAkGA1UE\nBhMCVVMxDTALBgNVBAgTBFRlc3QxDTALBgNVBAcTBFRlc3QxDTALBgNVBAoTBFRl\nc3QxDTALBgNVBAsTBFRlc3QxEjAQBgNVBAMTCWxvY2FsaG9zdDAeFw0yNjA4MDMy\nMjM1NTRaFw0zNjA3MzEyMjM1NTRaMF0xCzAJBgNVBAYTAlVTMQ0wCwYDVQQIEwRU\nZXN0MQ0wCwYDVQQHEwRUZXN0MQ0wCwYDVQQKEwRUZXN0MQ0wCwYDVQQLEwRUZXN0\nMRIwEAYDVQQDEwlsb2NhbGhvc3QwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGK\nAoIBgQC2nQAKm17lV/PNmgxbQw+Ht9muS4YTuHx7FV90FUk2nBJgGTIKxX9ge1rs\n2G+z0Pp5k0ZmnhpS0KQvcYUkOkQw8UiamD/moe2BUyZuYTqpQ5xfsAHbfEHQfYn3\n7txawjYHofQw2/j2C4ejEIe/cbdO+ukbwfwJSOQ4kyHDEZ8TaddNacPoFMZwF0UB\n/QYJyZOD/SRiN+uCR1HuqJxthP7yi8O7nUv6AH6MjjIO/Z/bBS1CYvG/CvVBjMHZ\nVQb7tNIfUSIEJAHBqi/IMWh2PNH8VE/fbfkKU36HZxrz81dGN3AMA6eZKcxx64y3\nsPM0afGxAYQ5fYkxDlNSIjmGZcndaonaYaIMLXsL4lCYSy/XfgcSQTUkYY58vhTK\nC47HHOxOJd4pRoOFvdsT9IJglr9S9qpDmJ1eK0oPmd401buj0JR35sj/YtuDPM/W\n4+9SiOMMMR/KtSuG7MJh+iIACF+6pfldzEYW2YEE5TZB17LkKJiXQHxvgXEMy9fG\n/c7xmUECAwEAAaMhMB8wHQYDVR0OBBYEFJ/2qat8TjXYoB1yK+2aJJw0SYu2MA0G\nCSqGSIb3DQEBDAUAA4IBgQB5nUi4HVDsrA2kq2vMjRrUNAhEoLJN9Bhx2kdprOCS\nnJa25iACNXf5RP00cgd9x2uUaOdsvDc9+23+DekKT8XFah/6de7vd/jcoN3KgFki\nFcm7SRCjvc1sxyO9sjMu3Bl1JPmxx/io21/rfA5Gyf10rv1k3h3QPXDQc1Rrc7np\nAZO9LsIxBfIQ6uq8W2AUTd4JlQQ9FPOFLdoYJNDJ9rgXxpCgWfPL/lAE1+wtdbvi\nag23xLmOFnxuHSJxM7UAWnJKqwm5DqvGWYJ6tsmnIkq2tECjLKO6/5ybCeUMFTX2\nw68MTUk2BgifIU3Ldwv6B+N75UviPP3tlAOG2qEuqZXpKdKo1lJZ4VyMryAAQpvC\nu4WpkReJg/Yerzrg6Q5JSZvBnbIihHhsYXwmPrkFb7CPR7xqHjwsE8Qv+iDlbmey\n/mRTYn3XEDNVqYrTb1qledpjkN0dWPQe9kPHHiYq3Q2j23blQpQj21eA+7PaiRnw\nLVn2HZR5g1Qk50ZwpXKpmvg=\n-----END CERTIFICATE-----"}'

docker run --rm -i --network host \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  amazon/aws-cli \
  --endpoint-url http://localhost:4566 \
  --region us-east-1 \
  secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --secret-string "$SECRET_VALUE"

echo "✅ Secreto '$SECRET_NAME' creado exitosamente en LocalStack."
