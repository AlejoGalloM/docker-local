
#!/bin/bash

docker ps

#------------------ACE-------------------------#
ACE=$(docker ps | grep :$(ACE_WEB_TEST_PORT))
ACE=$(echo ${ACE:0:5})
[ "${#ACE}" -gt 1 ] && docker stop $ACE && echo 'ACE Puerto $(ACE_WEB_TEST_PORT) no disponible' || echo 'ACE Puerto $(ACE_WEB_TEST_PORT) disponible'
echo "Este es el container del ACE $ACE"
#------------------ACEC-------------------------#
ACEC=$(docker ps -a | grep ace$(APPLICATION_NAME))
ACEC=$(echo ${ACEC:0:5})
[ "${#ACEC}" -gt 1 ] && docker stop $ACEC && docker rm $ACEC && echo 'Contenedor ace$(APPLICATION_NAME) Eliminado' || echo 'ACE Contenedor ace$(APPLICATION_NAME) disponible'
#------------------MQ-------------------------#
MQ=$(docker ps | grep :$(MQ_SERVER_TEST_PORT))
MQ=$(echo ${MQ:0:5})
[ "${#MQ}" -gt 1 ] && docker stop $MQ && echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) no disponible' || echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) disponible'
echo "Este es el container del MQ $MQ"
#------------------MQC-------------------------#
MQC=$(docker ps -a | grep mq$(APPLICATION_NAME))
MQC=$(echo ${MQC:0:5})
[ "${#MQC}" -gt 1 ] && docker stop $MQC && docker rm $MQC && echo 'Contenedor mq$(APPLICATION_NAME) Eliminado' || echo 'MQ Contenedor mq$(APPLICATION_NAME) disponible'
#------------------GO-------------------------#
GO=$(docker ps | grep :$(MOCK_WEB_PORT))
GO=$(echo ${GO:0:5})
[ "${#GO}" -gt 1 ] && docker stop $GO && echo 'GO Puerto $(MOCK_WEB_PORT) no disponible' || echo 'GO Puerto $(MOCK_WEB_PORT) disponible'
echo "Este es el container del GO $GO"
#------------------GOC-------------------------#
GOC=$(docker ps -a | grep go$(APPLICATION_NAME))
GOC=$(echo ${GOC:0:5})
[ "${#GOC}" -gt 1 ] && docker stop $GOC && docker rm $GOC && echo 'Contenedor go$(APPLICATION_NAME) Eliminado' || echo 'GO Contenedor go$(APPLICATION_NAME) disponible'
#------------------DB-------------------------#
DB=$(docker ps | grep :$(DB_PORT))
DB=$(echo ${DB:0:5})
[ "${#DB}" -gt 1 ] && docker stop $DB && echo 'DB Puerto $(DB_PORT) no disponible' || echo 'DB Puerto $(DB_PORT) disponible'
echo "Este es el container del DB $DB"
#------------------DBC-------------------------#
DBC=$(docker ps -a | grep db$(APPLICATION_NAME))
DBC=$(echo ${DBC:0:5})
[ "${#DBC}" -gt 1 ] && docker stop $DBC && docker rm $DBC && echo 'Contenedor db$(APPLICATION_NAME) Eliminado' || echo 'DB Contenedor db$(APPLICATION_NAME) disponible'
